/**
 * APICloud Modules
 * Copyright (c) 2014-2015 by APICloud, Inc. All Rights Reserved.
 * Licensed under the terms of the The MIT License (MIT).
 * Please see the license.html included with this distribution for details.
 */
package com.uzmap.pkg.uzmodules.UIInput;

import org.json.JSONObject;

import android.content.Context;
import android.text.TextUtils;

import com.uzmap.pkg.uzcore.uzmodule.UZModuleContext;
import com.uzmap.pkg.uzkit.UZUtility;

public class Config {

	public static final String KEYBOARD_DEFAULT = "default";
	public static final String KEYBOARD_SEARCH = "search";
	public static final String KEYBOARD_NUMBER = "number";
	public static final String KEYBOARD_URL = "url";
	public static final String KEYBOARD_EMAIL = "email";
	public static final String KEYBOARD_NEXT = "next";
	public static final String KEYBOARD_SEND = "send";
	public static final String KEYBOARD_DONE = "done";

	public static final String EVENT_SHOW = "show";
	public static final String EVENT_TEXT_CHANGE = "change";
	public static final String EVENT_KEYBOARD_POP_UP = "popup";
	public static final String EVENT_KEYBOARD_CLOSE = "close";
	public static final String EVENT_SERACH = "search";

	public int x = 0;
	public int y = 0;
	public int w;
	public int h = 40;

	public int maxLines = 1;

	public int bgColor = 0xFFFFFFFF;
	public int size = 14;
	public int color = 0xFF000000;

	public int placeHolderColor = 0xFFCCCCCC;
	public String placeHolderIcon;

	public String placeHolder;
	public boolean autoFocus = true;

	public String keyBoardType = KEYBOARD_DEFAULT;

	public String fixedOn;
	public boolean fixed = true;

	public boolean multiline = false;
	
	public String inputType;
	
	public int maxStringLength = -1;
	
	public String alignment = "left";
	
	public boolean isCenterVertical = true;

	public Config(Context context, UZModuleContext uzContext) {

		w = ViewUtil.getScreenWidth(context);

		JSONObject rectObj = uzContext.optJSONObject("rect");
		if (rectObj != null) {
			if (!rectObj.isNull("x")) {
				x = rectObj.optInt("x");
			}
			if (!rectObj.isNull("y")) {
				y = rectObj.optInt("y");
			}
			if (!rectObj.isNull("w")) {
				w = rectObj.optInt("w");
			}
			if (!rectObj.isNull("h")) {
				h = rectObj.optInt("h");
			}
		}
		
		inputType = uzContext.optString("inputType", "text");

		JSONObject stylesObj = uzContext.optJSONObject("styles");
		if (stylesObj != null) {
			if (!stylesObj.isNull("bgColor") && !TextUtils.isEmpty(stylesObj.optString("bgColor"))) {
				bgColor = UZUtility.parseCssColor(stylesObj.optString("bgColor"));
			}
			
			if(!stylesObj.isNull("size")){
				size = stylesObj.optInt("size");
			}

			if (!stylesObj.isNull("color") && !TextUtils.isEmpty(stylesObj.optString("color"))) {
				color = UZUtility.parseCssColor(stylesObj.optString("color"));
			}

			JSONObject placeholderObj = stylesObj.optJSONObject("placeholder");
			if (placeholderObj != null) {
				if (!placeholderObj.isNull("color") && !TextUtils.isEmpty(placeholderObj.optString("color"))) {
					placeHolderColor = UZUtility.parseCssColor(placeholderObj.optString("color"));
				}
				if (!placeholderObj.isNull("icon") && !TextUtils.isEmpty(placeholderObj.optString("icon"))) {
					placeHolderIcon = placeholderObj.optString("icon");
				}
			}
			
		}
		
		maxStringLength = uzContext.optInt("maxStringLength");
		alignment = uzContext.optString("alignment", "left");
		
		if (!uzContext.isNull("placeholder")) {
			placeHolder = uzContext.optString("placeholder");
		}
		
		isCenterVertical = uzContext.optBoolean("isCenterVertical", true);

		if (!uzContext.isNull("autoFocus")) {
			autoFocus = uzContext.optBoolean("autoFocus");
		}

		if (!uzContext.isNull("maxRows")) {
			maxLines = uzContext.optInt("maxRows");
		}

		if (!uzContext.isNull("keyboardType")) {
			keyBoardType = uzContext.optString("keyboardType");
		}

		if (!uzContext.isNull("fixedOn")) {
			fixedOn = uzContext.optString("fixedOn");
		}

		if (!uzContext.isNull("fixed")) {
			fixed = uzContext.optBoolean("fixed", true);
		}
	}
}
