package com.bugblat.bx;

import java.io.ByteArrayOutputStream;
import java.lang.Math;
import java.lang.Thread;

import android.content.Context;
import android.os.AsyncTask;

import com.ftdi.j2xx.D2xxManager;
import com.ftdi.j2xx.FT_Device;

//=====================================================================
public class BXIF {

  private static final int VID_FT               = 0x0403;     // FTDI VID
  private static final int PID_FT230            = 0x6015;     // FTDI FT230 PID

  private static final int BX_VID               = VID_FT;
  private static final int BX_PID               = PID_FT230;

  private static final int TX_BIT               = 0;          // from FT230
  private static final int RX_BIT               = 1;          // to FT230
  private static final int RTS_BIT              = 2;          // from FT230
  private static final int CTS_BIT              = 3;          // to FT230

  //------------------------------------------
  // CBUS bits are
  //    0 - RST      0: normaloperation, 1: FPGA GSRn
  //    1 - K24
  //    2 - JTAGena  0: XO2 pins are GPIO, 1: pins are JTAG
  //    3 - SUSPn    0: effectively GSRn, 1: normal operation
  //
  // bits RST and JTAGena are GPIO, driven by CBUS_BITBANG

  private static final int CBUS_RST_BIT         = 0;
  private static final int CBUS_K24_BIT         = 1;
  private static final int CBUS_JTAGena_BIT     = 2;
  private static final int CBUS_SUSPn_BIT       = 3;

  private static final int CBUS_BITBANG_OUTDIR  = 0xf0;       // all lines as outputs

  private static final int READ_SLEEP_MILLISECS = 15;
  private static final int MAX_READ_LOOP        = 20;
  private static final int MAX_READ_BYTES       = 512;

//private static final int USB_TIMEOUT          = 5000;       // milliseconds

  //----------------------------------------
  // sub-addresses to the FPGA logic
  private static final int A_ADDR  = (0<<6);     /* sending an address */
  private static final int D_ADDR  = (1<<6);     /* sending data       */
  private static final int T_ADDR  = (2<<6);     /* sending 6 count bits, trigger readback */
  private static final int H_ADDR  = (3<<6);     /* sending 6 count bits, no readback */

  //----------------------------------------
  private static final byte[] NO_BYTES = {};

  Context       Fcontext;
  D2xxManager   Fd2xxManager;
  FT_Device     ftDevice;
  String        FserialNumber;

  ByteArrayOutputStream FwrBuf = new ByteArrayOutputStream();

  //----------------------------------------
  /* Constructor */
  public BXIF(Context parentContext, D2xxManager ftdid2xxContext) {
    Fcontext     = parentContext;
    Fd2xxManager = ftdid2xxContext;
    open();
    }

  //----------------------------------------
  protected void finalize( ) throws Throwable {
    close();
    super.finalize();
    }

  // ====================================================================
  int readQclear() {
    int lastInput = -1;
    byte[] buf = new byte[MAX_READ_BYTES];

    while (isOpen()) {
      int numAvail = ftDevice.getQueueStatus();
      if (numAvail == 0)
          break;

      // clear in big lumps - FTX internal buffer is 512 bytes
      int n = Math.min(numAvail, buf.length);
      int numRead = ftDevice.read(buf, n);
      if (numRead <= 0)
        return -1;                              // never fail or throw
      lastInput = buf[numRead-1];
      }
    return lastInput;
    }

  //=============================================
  private class BXrwException extends Exception {
    public BXrwException(String message) {
      super(message);
      }
    }

  //=============================================
  private class _reader extends AsyncTask<Integer, Void, byte[]> {
    @Override
    protected byte[] doInBackground(Integer... params) {
      ByteArrayOutputStream rdBuf = new ByteArrayOutputStream();

      int needed = params[0];
      byte[] buf = new byte[needed];
      int maxLoop = MAX_READ_LOOP * (1+(needed/1000)), numRead = 0;

      try {
        for (int loop=0; loop < maxLoop; loop++) {
          int numAvailable = ftDevice.getQueueStatus();
          if (numAvailable <= 0)
            Thread.sleep(READ_SLEEP_MILLISECS);
          else {
            int numToRead = Math.min(numAvailable, needed);
            numRead = ftDevice.read(buf, numToRead);
            if (numRead > 0)
              rdBuf.write(buf, 0, numRead);
            needed -= numRead;
            if (needed == 0)
              return rdBuf.toByteArray();
            }
          }
        }
      catch (InterruptedException e) {
        Thread.interrupted();
        }
      return NO_BYTES;
      }

    @Override
    protected void onPostExecute(byte[] res) {}

    @Override
    protected void onPreExecute() {}

    @Override
    protected void onProgressUpdate(Void... values) {}
    }

  //=============================================
  // always for <= 512 bytes
  byte[] _read(int aNeeded) throws BXrwException  {
    if (aNeeded <= 0)
      return new byte[0];

    if (!isOpen())
      throw new BXrwException("r");

    try {
      _reader reader = new _reader();
      reader.execute(aNeeded);
      return reader.get();
      }
    catch (Exception e) {
      throw new BXrwException("r");
      }
    }

  //---------------------------------------------
  int _write(byte[] buf, int aCount) throws BXrwException {
    if (aCount <= 0)
      return 0;

    if (!isOpen())
      throw new BXrwException("w");

    int numWritten = ftDevice.write(buf, aCount);

    if (numWritten != aCount)
      throw new BXrwException("w");
    return numWritten;
    }

  // ====================================================================
  void tx(int x) {
    FwrBuf.write(x);
    }
  public void ta(int x) { tx(A_ADDR | (x % 64)); }
  public void td(int x) { tx(D_ADDR | (x % 64)); }
  public void tt(int x) { tx(T_ADDR | (x % 64)); }
  public void th(int x) { tx(H_ADDR | (x % 64)); }

  //---------------------------------------------
  public boolean appFlush() {
    int wrBufSize = FwrBuf.size();
    if (wrBufSize <= 0)
      return true;

    try {
      _write(FwrBuf.toByteArray(), wrBufSize);
      FwrBuf.reset();
      return true;
      }
    catch(BXrwException e) {
      close();
      FwrBuf.reset();
      return false;
      }
    }

  //---------------------------------------------
  public boolean appWrite(byte[] aWrData, int aWrLen) {
    try {
      _write(aWrData, aWrLen);
      return true;
      }
    catch(BXrwException e) {
      close();
      return false;
      }
    }

  //---------------------------------------------
  public byte[] appRead(int aCount) {
    try {
      return _read(aCount);
      }
    catch(BXrwException e) {
      close();
      return NO_BYTES;
      }
    }

  //---------------------------------------------
  byte[] _appReadBlock(int aCount) throws BXrwException {
    if (aCount <= 0)
      return NO_BYTES;

    th(aCount/64);
    tt(aCount);                             // effectively aBlockCount mod 64
    appFlush();
    return _read(aCount);                   // exception thrown if not OK
    }

  //---------------------------------------------
  public byte[] appReadReg(int aRegNum, int aCount) {
    if (aCount <= 0)
      return NO_BYTES;

    try {
      ta(aRegNum);
      if (aCount <= MAX_READ_BYTES)
        return _appReadBlock(aCount);

      ByteArrayOutputStream rdBuf = new ByteArrayOutputStream();
      while (aCount > 0) {
        int num = Math.min(aCount, MAX_READ_BYTES);
        byte[] buf = _appReadBlock(num);
        rdBuf.write(buf, 0, num);
        aCount -= num;
        }
      return rdBuf.toByteArray();
      }
    catch(BXrwException e) {
      close();
      }
    return NO_BYTES;
    }

  // ====================================================================
  void setCbusBitbangMode(int RSTval, int JtagEnableVal) {
    int v = ((RSTval & 1)        << CBUS_RST_BIT    )
          + ((JtagEnableVal & 1) << CBUS_JTAGena_BIT)
          + CBUS_BITBANG_OUTDIR;
  ftDevice.setBitMode((byte) v, D2xxManager.FT_BITMODE_CBUS_BITBANG);
  }

  //---------------------------------------------
  void clearBitbangMode() {
    setCbusBitbangMode(0, 0);                 // set default values
    ftDevice.setBitMode((byte) 0, D2xxManager.FT_BITMODE_RESET);
    }

  //---------------------------------------------
  public boolean toggleRST() {
  if (isOpen()) {
    try {
      setCbusBitbangMode(1, 0);               // RST ON, then OFF
      setCbusBitbangMode(0, 0);
      clearBitbangMode();
      readQclear();
      return true;
      }
    catch(Exception e) {                      // never throw
      }
    }
  return false;
  }

  //----------------------------------------
  public boolean isOpen() {
    if (null == ftDevice)
      return false;
    boolean b = ftDevice.isOpen();
    return b;
    }

  //----------------------------------------
  public void close() {
    if (isOpen())
      ftDevice.close();
    }

  //----------------------------------------
  public boolean open() {
    if (isOpen()) {                             // already open
      readQclear();
      return true;
      }

    int devCount = Fd2xxManager.createDeviceInfoList(Fcontext);
    int[][] vidpidList = Fd2xxManager.getVIDPID();

    for (int ix=0; ix<devCount; ix++) {
      if ((vidpidList[0][ix] != BX_VID) || (vidpidList[1][ix] != PID_FT230))
        continue;

      D2xxManager.FtDeviceInfoListNode info
                                = Fd2xxManager.getDeviceInfoListDetail(ix);

      boolean okDescription = info.description.startsWith("Fan")
                              || info.description.startsWith("BX");
      boolean okSerial = info.serialNumber.startsWith("BX");

      if (   (info.type != D2xxManager.FT_DEVICE_X_SERIES)
          || (!okDescription) || (!okSerial)   )
        continue;

      FserialNumber = info.serialNumber;

      ftDevice = Fd2xxManager.openByIndex(Fcontext, ix);

      if (isOpen()) {
        ftDevice.setBitMode((byte) 0, D2xxManager.FT_BITMODE_RESET);
        ftDevice.setBaudRate(3 * 1000 * 1000);
        ftDevice.setDataCharacteristics(D2xxManager.FT_DATA_BITS_8,
                        D2xxManager.FT_STOP_BITS_1, D2xxManager.FT_PARITY_NONE);
        ftDevice.setFlowControl(D2xxManager.FT_FLOW_NONE, (byte)0, (byte)0);
        ftDevice.setLatencyTimer((byte) 16);
        ftDevice.purge((byte) (D2xxManager.FT_PURGE_TX |
                                                    D2xxManager.FT_PURGE_RX));

        toggleRST();                        // also clears any bitbang mode
        readQclear();
        FwrBuf.reset();
        }
      if (isOpen())                         // still open OK?
        return true;
      else
        close();
      }

    return false;
    }

  //----------------------------------------
  public boolean rescan() {
    return isOpen() ? true : open();
    }

  //----------------------------------------
  public String serialNumber() {
    return FserialNumber;
    }

  //----------------------------------------
  public FT_Device getHandle() {
    return ftDevice;
    }

  }   // end of class

// EOF ----------------------------------------------------------------
