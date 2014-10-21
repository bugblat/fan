package com.giderosmobile.android;

import android.app.Activity;

import com.ftdi.j2xx.D2xxManager;

import com.bugblat.bx.BXIF;

public class bxPlugin {
  public static D2xxManager mD2xxManager = null;

  static Activity mActivity;
  static BXIF     mBXIF = null;
  static boolean  mWasOpen;


  // on create event from Gideros
  // receives reference to current activity
  // just in case if you might need it
  public static void onCreate(Activity activity) {
    mActivity = activity;

    try {
      mD2xxManager = D2xxManager.getInstance(mActivity);
      mBXIF = new BXIF(mActivity, mD2xxManager);
      mBXIF.close();
      mWasOpen = false;
      }
    catch (D2xxManager.D2xxException ex) {
      ex.printStackTrace();
      }
    }

  // could implement pause/resume, but this will toggle global reset.
  public static void onPause() {
    mWasOpen = mBXIF.isOpen();
//  mBXIF.close();
    }
  public static void onResume() {
    if (mWasOpen) {
//    mBXIF.open();
      }
    }

  public static void onStart()   {}
  public static void onStop()    {}
  public static void onDestroy() {
    mBXIF.close();
    mBXIF = null;
    }

  //----------------------------------------
  public static int addTwoIntegers(int a, int b) {
    return a+b;
    }

  //----------------------------------------
  public static void ta(int v) { mBXIF.ta(v); }
  public static void td(int v) { mBXIF.td(v); }
  public static void tt(int v) { mBXIF.tt(v); }
  public static void th(int v) { mBXIF.th(v); }

  //----------------------------------------
  public static boolean appWrite(byte[] d, int len) {
    return mBXIF.appWrite(d, len);
    }
  public static byte[] appRead(int len) {
    return mBXIF.appRead(len);
    }
  public static byte[] appReadReg(int reg, int len) {
    return mBXIF.appReadReg(reg, len);
    }

  public static boolean appFlush()    { return mBXIF.appFlush();     }
  public static boolean toggleRST()   { return mBXIF.toggleRST();    }
  public static boolean isOpen()      { return mBXIF.isOpen();       }
  public static void    close()       {        mBXIF.close();        }
  public static boolean open()        { return mBXIF.open();         }
  public static boolean rescan()      { return mBXIF.rescan();       }

  public static String  serialNumber(){ return mBXIF.serialNumber(); }
  }

// EOF ----------------------------------------------------------------
/*
*/
