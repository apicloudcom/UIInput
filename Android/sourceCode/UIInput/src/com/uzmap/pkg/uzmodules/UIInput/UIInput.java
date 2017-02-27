/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */

package com.uzmap.pkg.uzmodules.UIInput;

import java.io.IOException;
import java.io.InputStream;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Rect;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.InputType;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.util.SparseArray;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnFocusChangeListener;
import android.view.ViewTreeObserver.OnGlobalLayoutListener;
import android.view.WindowManager;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.ImageView.ScaleType;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.TextView.OnEditorActionListener;

import com.uzmap.pkg.uzcore.UZCoreUtil;
import com.uzmap.pkg.uzcore.UZWebView;
import com.uzmap.pkg.uzcore.uzmodule.UZModule;
import com.uzmap.pkg.uzcore.uzmodule.UZModuleContext;
import com.uzmap.pkg.uzkit.UZUtility;

public class UIInput extends UZModule {

	private Config mConfig;
	
	private static String EVENT_FOCUS_GET  = "becomeFirstResponder";
	private static String EVENT_FOCUS_LOST = "resignFirstResponder";

	public UIInput(UZWebView webView) {
		super(webView);
	}
	
	private SparseArray<View> views = new SparseArray<View>();
	private int count = -1;
	
	private static final int EDIT_TEXT_ID = 0x100;

	public void jsmethod_open(final UZModuleContext uzContext) {
		
		getKeyboardHeight();
		mConfig = new Config(getContext(), uzContext);
		
		RelativeLayout mContainerLayout = new RelativeLayout(getContext());
		
		count ++;
		views.put(count, mContainerLayout);
		
		// /// EditText
		RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(mConfig.w, mConfig.h);
		params.leftMargin = mConfig.x;
		params.topMargin = mConfig.y;

		RelativeLayout.LayoutParams editParam = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT);
		final XEditText mInputField = new XEditText(getContext());
		mInputField.setId(EDIT_TEXT_ID);
		mInputField.setLayoutParams(editParam);
		mContainerLayout.addView(mInputField);
		mInputField.setTextSize(mConfig.size);
		
		mInputField.setTag(count);

		// set EditText style
		if (Config.KEYBOARD_DEFAULT.equals(mConfig.keyBoardType)) {
			mInputField.setImeOptions(EditorInfo.IME_ACTION_NONE);
		}
		if (Config.KEYBOARD_NUMBER.equals(mConfig.keyBoardType)) {
			mInputField.setInputType(InputType.TYPE_CLASS_NUMBER);
		}
		if (Config.KEYBOARD_SEARCH.equals(mConfig.keyBoardType)) {
			mInputField.setImeOptions(EditorInfo.IME_ACTION_SEARCH);
			mInputField.setInputType(EditorInfo.TYPE_CLASS_TEXT);
			mInputField.setSingleLine(true);
		}
		if (Config.KEYBOARD_URL.equals(mConfig.keyBoardType)) {
			mInputField.setImeOptions(EditorInfo.IME_ACTION_NONE);
		}

		if (Config.KEYBOARD_EMAIL.equals(mConfig.keyBoardType)) {
			mInputField.setImeOptions(EditorInfo.IME_ACTION_NONE);
		}
		
		if(Config.KEYBOARD_NEXT.equals(mConfig.keyBoardType)){
			mInputField.setImeOptions(EditorInfo.IME_ACTION_NEXT);
			mInputField.setInputType(EditorInfo.TYPE_CLASS_TEXT);
			mInputField.setSingleLine(true);
		}

		mInputField.setBackgroundColor(mConfig.bgColor);
		mInputField.setTextColor(mConfig.color);
		mInputField.setHintTextColor(mConfig.placeHolderColor);
		mInputField.setPadding(UZUtility.dipToPix(5), 0, 0, 0);

		mInputField.setHint(mConfig.placeHolder);

		if (mConfig.maxLines <= 1) {
			mInputField.setSingleLine(true);
			mInputField.setGravity(Gravity.CENTER_VERTICAL);
		} else {
			mInputField.setSingleLine(false);
			mInputField.setMaxLines(mConfig.maxLines);
			mInputField.setGravity(Gravity.TOP);
		}
		
		if (mConfig.autoFocus) {
			// force request focus
			forceRequestFocus(mInputField);
			
			// Pop the SoftInputKeyBoard
			new Handler().postDelayed(new Runnable() {
				@Override
				public void run() {
					getContext().getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
					showSoftInputKeyBoard(mInputField);
				}
			}, 300);

		} else {
			new Handler().postDelayed(new Runnable() {
				@Override
				public void run() {
					getContext().getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE);
				}
			}, 300); 
		}
		
		// ------------ ImageView setting ------------- 
		RelativeLayout.LayoutParams imageParams = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.WRAP_CONTENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
		imageParams.addRule(RelativeLayout.ALIGN_PARENT_LEFT);
		imageParams.addRule(RelativeLayout.CENTER_VERTICAL);
		final ImageView leftIcon = new ImageView(getContext());
		leftIcon.setLayoutParams(imageParams);
		leftIcon.setScaleType(ScaleType.CENTER_CROP);
		final Bitmap bitmap = getBitmap(mConfig.placeHolderIcon);
		leftIcon.setImageBitmap(bitmap);
		
		if (bitmap != null) {
			mInputField.setPadding(bitmap.getWidth() + 5, 0, 0, 0);
		}

		mInputField.addTextChangedListener(new TextWatcher() {
			
			@Override
			public void onTextChanged(CharSequence arg0, int arg1, int arg2, int arg3) {
				callback(uzContext, (Integer)mInputField.getTag(), Config.EVENT_TEXT_CHANGE, true);
			}

			@Override
			public void beforeTextChanged(CharSequence arg0, int arg1, int arg2, int arg3) {
				// NO-OP
			}

			@Override
			public void afterTextChanged(Editable arg0) {
				// NO-OP
			}
			
		});

		mInputField.setOnEditorActionListener(new OnEditorActionListener() {

			@Override
			public boolean onEditorAction(TextView arg0, int arg1, KeyEvent arg2) {
				if (arg1 == EditorInfo.IME_ACTION_SEARCH) {
					callback(uzContext, count, Config.EVENT_SERACH, true);
				}
				return false;
			}
			
		});
		
		mContainerLayout.addView(leftIcon);
		mInputField.setBackgroundColor(mConfig.bgColor);
		
		insertViewToCurWindow(mContainerLayout, params, mConfig.fixedOn, mConfig.fixed);
		callback(uzContext, count, Config.EVENT_SHOW, true);
		
	}
	
	public void jsmethod_close(UZModuleContext uzContext) {
		int id = uzContext.optInt("id");
		View layout = views.get(id);
		if(layout != null){
			removeViewFromCurWindow(layout);
		}
	}
	
	public void jsmethod_hide(UZModuleContext uzContext) {
		int id = uzContext.optInt("id");
		View layout = views.get(id);
		if(layout != null){
			layout.setVisibility(View.GONE);
		}
	}

	public void jsmethod_show(UZModuleContext uzContext) {
		int id = uzContext.optInt("id");
		View layout = views.get(id);
		if(layout != null){
			layout.setVisibility(View.VISIBLE);
		}
	}

	public void jsmethod_insertValue(UZModuleContext uzContext) {
		
		int id = uzContext.optInt("id");
		View layout = views.get(id);
		if(layout == null){
			return;
		}
		XEditText mInputField = (XEditText)layout.findViewById(EDIT_TEXT_ID);
		if(mInputField != null) {
			int index = 0;
			if (!TextUtils.isEmpty(mInputField.getText().toString())) {
				index = mInputField.getText().toString().length();
			}
			if (!uzContext.isNull("index")) {
				index = uzContext.optInt("index");
			}
			if (!uzContext.isNull("msg")) {

				String msg = uzContext.optString("msg");
				StringBuilder sb = new StringBuilder();
				sb.append(mInputField.getText().toString());

				String inputStr = mInputField.getText().toString();

				if (!TextUtils.isEmpty(inputStr) && index < inputStr.length()) {
					sb.insert(index, msg);
					mInputField.setText(sb.toString());
					mInputField.setSelection(index);
				} else {
					mInputField.append(msg);
				}
			}
		}
	}
	
	public UZModuleContext eventContext;
	public String eventName;
	
	public void jsmethod_addEventListener(UZModuleContext uzContext){
		eventContext = uzContext;
		eventName = uzContext.optString("name");
		
		int id = uzContext.optInt("id");
		View layout = views.get(id);
		if(layout == null){
			return;
		}
		final XEditText mInputField = (XEditText)layout.findViewById(EDIT_TEXT_ID);
		mInputField.setOnFocusChangeListener(new OnFocusChangeListener() {
			
			@Override
			public void onFocusChange(View arg0, final boolean arg1) {
				if (!arg1) {
					hideSoftInputKeyBoard(mInputField);
				}
				
				new Handler(Looper.getMainLooper()).postDelayed(new Runnable(){

					@Override
					public void run() {
						if(eventContext != null && !TextUtils.isEmpty(eventName)){
							 if(eventName.equals(EVENT_FOCUS_GET) && arg1){
								 JSONObject ret = new JSONObject();
								 try {
									ret.put("keyboardHeight", UZCoreUtil.pixToDip(mKeyboardHeight));
								} catch (JSONException e) {
									e.printStackTrace();
								}		 
								 eventContext.success(ret, false);
							 }
							 
							 if(eventName.equals(EVENT_FOCUS_LOST) && !arg1){
								 eventContext.success(new JSONObject(), false);
							 }
						 }
					}
				}, 300);
				
				 
			}
		});
	}

	public void jsmethod_setAttr(UZModuleContext uzContext) {
		
		int id = uzContext.optInt("id");
		View layout = views.get(id);

		if (!uzContext.isNull("h") && layout != null) {
			int h = uzContext.optInt("h");
			RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(mConfig.w, h);

			params.leftMargin = UZUtility.dipToPix(mConfig.x);
			params.topMargin = UZUtility.dipToPix(mConfig.y);

			removeViewFromCurWindow(layout);
			insertViewToCurWindow(layout, params, mConfig.fixedOn, false);
		}
	}

	public Bitmap getBitmap(String imgPath) {
		if (TextUtils.isEmpty(imgPath)) {
			return null;
		}
		String realPath = makeRealPath(imgPath);
		try {
			InputStream input = UZUtility.guessInputStream(realPath);
			Bitmap retBitmap = BitmapFactory.decodeStream(input);
			input.close();
			return retBitmap;
		} catch (IOException e) {
			e.printStackTrace();
		}
		return null;
	}

	public void forceRequestFocus(EditText editText) {
		if (editText != null) {
			editText.setFocusable(true);
			editText.setFocusableInTouchMode(true);
			editText.requestFocus();
		}
	}

	// show the SoftInputKeyboard
	public void showSoftInputKeyBoard(EditText inputField) {
		InputMethodManager imm = (InputMethodManager) inputField.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
		imm.showSoftInput(inputField, 0);
	}

	public void hideSoftInputKeyBoard(EditText inputField) {
		InputMethodManager imm = (InputMethodManager) inputField.getContext().getSystemService(Context.INPUT_METHOD_SERVICE);
		if (imm.isActive()) {
			imm.hideSoftInputFromWindow(inputField.getApplicationWindowToken(), 0);
		}
	}

	public void jsmethod_value(UZModuleContext uzContext) {
		
		int id = uzContext.optInt("id");
		View layout = views.get(id);
		if(layout == null){
			return;
		}
		XEditText mInputField = (XEditText)layout.findViewById(EDIT_TEXT_ID);
		if (mInputField != null && !uzContext.isNull("msg")) {
			String msg = uzContext.optString("msg");
			mInputField.setText(msg);
			mInputField.setSelection(msg.length());
			callback(uzContext, true, uzContext.optString("msg"));
		}

		if (mInputField != null && uzContext.isNull("msg")) {
			callback(uzContext, true, mInputField.getText().toString());
		}
	}

	public void callback(UZModuleContext uzContext, boolean status, String msg) {
		JSONObject ret = new JSONObject();
		try {
			ret.put("status", status);
			ret.put("msg", msg);
		} catch (JSONException e) {
			e.printStackTrace();
		}
		uzContext.success(ret, false);
	}

	public void callback(UZModuleContext uzContext, int id, String eventType, boolean status) {
		JSONObject ret = new JSONObject();
		try {
			if(id >= 0){
				ret.put("id", id + "");
			}
			ret.put("status", status);
			ret.put("eventType", eventType);
		} catch (JSONException e) {
			e.printStackTrace();
		}
		uzContext.success(ret, false);
	}

	/** 
	 * empty callback 
	 */
	public void callback(UZModuleContext uzContext) {
		JSONObject ret = new JSONObject();
		uzContext.success(ret, false);
	}

	/**
	 * KeyBoard PopListener
	 */
	public interface OnKeyBoardPopListener {
		public void onPopUp();
		public void onPopDown();
	}

	public OnKeyBoardPopListener popListener;

	public void setOnKeyBoardPopListener(OnKeyBoardPopListener popListener) {
		this.popListener = popListener;
	}
	
	public void jsmethod_popupKeyboard(UZModuleContext uzContext){
		
		int id = uzContext.optInt("id");
		final View layout = views.get(id);
		if(layout == null){
			return;
		}
		
		new Handler(Looper.getMainLooper()).postDelayed(new Runnable(){

			@Override
			public void run() {
				final XEditText mInputField = (XEditText)layout.findViewById(EDIT_TEXT_ID);
				if(mInputField != null){
					forceRequestFocus(mInputField);
					showSoftInputKeyBoard(mInputField);
				}
			}
			
		}, 300);
		
	}
	
	private int mKeyboardHeight = -1;
	
	public void getKeyboardHeight(){
		mContext.getWindow().getDecorView().getViewTreeObserver().addOnGlobalLayoutListener(new OnGlobalLayoutListener() {
			
			@Override
			public void onGlobalLayout() {
				
				Rect rect = new Rect();
				if(mContext != null){
					mContext.getWindow().getDecorView().getWindowVisibleDisplayFrame(rect);
					mKeyboardHeight = ViewUtil.getScreenHeight(mContext) - (rect.bottom - rect.top);
				}
			}
		});
	}
	
	public void jsmethod_closeKeyboard(UZModuleContext uzContext){
		
		int id = uzContext.optInt("id");
		View layout = views.get(id);
		if(layout == null){
			return;
		}
		
		XEditText mInputField = (XEditText)layout.findViewById(EDIT_TEXT_ID);
		if(mInputField != null){
			hideSoftInputKeyBoard(mInputField);
		}
		
	}
}