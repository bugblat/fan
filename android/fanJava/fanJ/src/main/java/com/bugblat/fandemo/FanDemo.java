package com.bugblat.fandemo;

import android.app.Fragment;
import android.app.Activity;
import android.content.Intent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.IntentFilter;
import android.content.res.Resources;
import android.hardware.usb.UsbManager;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import com.ftdi.j2xx.D2xxManager;
import com.ftdi.j2xx.FT_Device;
import com.bugblat.bx.BXIF;

//------------------------------------------
public class FanDemo extends Fragment {
  D2xxManager mD2xxManager = null;
  Activity    mActivity;

  Button      mBtnTest;
  TextView    mReg0Text;
  TextView    mDescText;

  BXIF        mBXIF = null;

  //----------------------------------------
  @Override
  public void onAttach(Activity activity) {
    mActivity = activity;
    super.onAttach(mActivity);
    try {
      // or activity.getApplicationContext() ??
      mD2xxManager = D2xxManager.getInstance(mActivity);
      }
    catch (D2xxManager.D2xxException ex) {
      ex.printStackTrace();
      }
    IntentFilter filter = new IntentFilter();
    filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED);
    filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
    filter.setPriority(500);
    mActivity.registerReceiver(mUsbReceiver, filter);
    }

  //----------------------------------------
  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container,
                                              Bundle savedInstanceState) {
    View view = inflater.inflate(R.layout.fandemo_layout, container, false);

    mReg0Text = (TextView)view.findViewById(R.id.Reg0);
    mDescText = (TextView)view.findViewById(R.id.Description);
    mBtnTest  = (Button)view.findViewById(R.id.ButtonTest);

    mBtnTest.setOnClickListener(
      new OnClickListener() {
        public void onClick(final View v) {
          runTest();
          }
        } );

    return view;
    }

  //----------------------------------------
  @Override
  public void onDetach() {
    mActivity.unregisterReceiver(mUsbReceiver);
    mBXIF = null;
    mD2xxManager = null;
    super.onDetach();
    }

  //----------------------------------------
  // USB broadcast receiver
  private final BroadcastReceiver mUsbReceiver = new BroadcastReceiver() {
    @Override
    public void onReceive(Context context, Intent intent) {
      String TAG = "FragL";
      String action = intent.getAction();
      if(UsbManager.ACTION_USB_DEVICE_DETACHED.equals(action)) {
        Log.i(TAG,"DETACHED...");
        }
      }
    };

  //----------------------------------------
  // called from button click
  void runTest() {
    if (mBXIF == null) {
      mBXIF = new BXIF(mActivity, mD2xxManager);
      mBXIF.close();
      }

    mBXIF.open();
    boolean ok = mBXIF.isOpen();
    String ts = (ok)
                ? "Device opened OK"
                : "Either no device or need to get permission!";

    Toast.makeText(mActivity, ts, Toast.LENGTH_SHORT).show();

    Resources res = getResources();
    String sReg  = res.getString(R.string.register_0);
    String sDesc = res.getString(R.string.description);

    if (ok) {
      FT_Device ftHandle = mBXIF.getHandle();

      byte[] buf = mBXIF.appReadReg(0, 21);
      String s = new String(buf);
      mReg0Text.setText(sReg + s);

      String desc = ftHandle.getDeviceInfo().description;
      mDescText.setText(sDesc + desc);

      mBXIF.close();
      }
    else {
      mReg0Text.setText(sReg);
      mDescText.setText(sDesc + "** not present **");
      }

    }

  }

// EOF --------------------------
