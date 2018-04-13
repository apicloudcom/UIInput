/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */
package com.uzmap.pkg.uzmodules.UIInput;

import android.content.Context;
import android.text.Selection;
import android.text.TextUtils;
import android.view.KeyEvent;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
import android.view.inputmethod.InputConnectionWrapper;
import android.widget.EditText;

public class XEditText extends EditText {
	
	public int mMaxChars = Integer.MAX_VALUE;

	public static final String TAG = "XEditText";

	public XEditText(Context context) {
		super(context);
	}
	
	public void setMaxChars(int max){
		this.mMaxChars = max;
	}
	
	@Override
	public InputConnection onCreateInputConnection(EditorInfo outAttrs) {
		return new ZanyInputConnection(this, super.onCreateInputConnection(outAttrs),true);
	}
	

	private class ZanyInputConnection extends InputConnectionWrapper {

		private XEditText mEditText;
		public ZanyInputConnection(XEditText editText, InputConnection target, boolean mutable) {
			super(target, mutable);
			this.mEditText = editText;
		}

		@Override
		public boolean commitText(CharSequence text, int newCursorPosition) {
			if(mEditText.getText().length() >= mMaxChars){
				return true;
			}
			return super.commitText(text, newCursorPosition);
		}

		@Override
		public boolean sendKeyEvent(KeyEvent event) {
			
			if (event.getKeyCode() == KeyEvent.KEYCODE_DEL) {
				XEditText edit = XEditText.this;
				
				if(TextUtils.isEmpty(edit.getText())){
					return false;
				}
				
				char c;
				if (edit.getSelectionStart() >= edit.getText().length()
						&& edit.getText().length() > 0) {

					c = edit.getText().charAt(edit.getSelectionStart() - 1);
				} else {
					c = edit.getText().charAt(edit.getSelectionStart());
				}

				if (!isNumeric(c) && !isChinese(c) && !isCharactor(c) && c != ' ') {
					deleteChar(edit);
				}
				deleteChar(edit);
				return false;
			}
			
			if (event.getKeyCode() == KeyEvent.KEYCODE_ENTER) {

				XEditText edit = XEditText.this;
				String text = edit.getText().toString();
				String newText = text + "\n";
				edit.setText(newText);
				try{
					Selection.setSelection(edit.getText(), newText.length());
				}catch(Exception e){
					e.printStackTrace();
				}
				

				return false;
			}
			
			if(event.getKeyCode() == KeyEvent.KEYCODE_0 
					|| event.getKeyCode() == KeyEvent.KEYCODE_1
					|| event.getKeyCode() == KeyEvent.KEYCODE_2
					|| event.getKeyCode() == KeyEvent.KEYCODE_3
					|| event.getKeyCode() == KeyEvent.KEYCODE_4
					|| event.getKeyCode() == KeyEvent.KEYCODE_5
					|| event.getKeyCode() == KeyEvent.KEYCODE_6
					|| event.getKeyCode() == KeyEvent.KEYCODE_7
					|| event.getKeyCode() == KeyEvent.KEYCODE_8
					|| event.getKeyCode() == KeyEvent.KEYCODE_9 ){
				
				XEditText edit = XEditText.this;
				int selectionStartIndex = edit.getSelectionStart();
				
				String result = insertChar(edit.getText().toString(), String.valueOf(event.getKeyCode() - 7), selectionStartIndex);
				edit.setText(result);
				try{
					edit.setSelection(selectionStartIndex + 1);
				} catch(Exception e){
					edit.setSelection(edit.getText().length());
				}
				
			}
			return super.sendKeyEvent(event);
		}
	}
	
	
	public String insertChar(String originalStr, String insertedStr, int index){
		
		String frontPart = originalStr.substring(0, index);
		String leftPart = originalStr.substring(index, originalStr.length());
		
		return frontPart + insertedStr + leftPart;
	}

	public void deleteChar(XEditText edit) {

		String text = edit.getText().toString();

		StringBuilder sb = new StringBuilder(text);
		int curCursorIndex = edit.getSelectionStart();

		if (text.length() > 0 && curCursorIndex > 0) {

			if (curCursorIndex >= sb.length()) {
				curCursorIndex -= 1;

				sb.deleteCharAt(curCursorIndex);
				edit.setText(sb.toString());
				Selection.setSelection(edit.getText(), sb.length());
				
			} else {
				curCursorIndex -= 1;
				sb.deleteCharAt(curCursorIndex);
				edit.setText(sb.toString());
				Selection.setSelection(edit.getText(), curCursorIndex);
				
			}

		}
	}

	public boolean isNumeric(char c) {

		int chr = c;
		if (chr < 48 || chr > 57)
			return false;
		return true;

	}

	public boolean isCharactor(char c) {
		int i = (int) c;
		if ((i >= 65 && i <= 90) || (i >= 97 && i <= 122)) {
			return true;
		} else {
			return false;
		}
	}

	public boolean isChinese(char c) {
		Character.UnicodeBlock ub = Character.UnicodeBlock.of(c);
		if (ub == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS
				|| ub == Character.UnicodeBlock.CJK_COMPATIBILITY_IDEOGRAPHS
				|| ub == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS_EXTENSION_A
				|| ub == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS_EXTENSION_B
				|| ub == Character.UnicodeBlock.CJK_SYMBOLS_AND_PUNCTUATION
				|| ub == Character.UnicodeBlock.HALFWIDTH_AND_FULLWIDTH_FORMS
				|| ub == Character.UnicodeBlock.GENERAL_PUNCTUATION) {
			return true;
		}
		return false;
	}
	
}
