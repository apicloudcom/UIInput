# 概述

输入框模块源码（内含iOS和android）

APICloud 的 UIInput 模块是一个输入框模块，可通过此模块打开一个模块开启键盘状态的输入框。但是由于本模块 UI 布局界面为固定模式，以及支持键盘类型局限，不能满足日益增长的广大开发者对模块样式的需求。因此，原生模块开发者，可以参考此模块的开发方式、接口定义等开发规范，或者基于此模块开发出更多符合产品设计的新 UI 布局的模块，希望此模块能起到抛砖引玉的作用。

## 模块接口文档

<p style="color: #ccc; margin-bottom: 30px;">来自于：APICloud 官方<a style="background-color: #95ba20; color:#fff; padding:4px 8px;border-radius:5px;margin-left:30px; margin-bottom:0px; font-size:12px;text-decoration:none;" target="_blank" href="//www.apicloud.com/mod_detail/UIInput">立即使用</a></p>

<div class="outline">

[open](#open)
[resetPosition](#resetPosition)
[close](#close)
[show](#show)
[hide](#hide)
[value](#value)
[insertValue](#insertValue)
[popupKeyboard](#popupKeyboard)
[closeKeyboard](#closeKeyboard)
[addEventListener](#addEventListener)
[getSelectedRange](#getSelectedRange)

</div>

# 论坛示例

为帮助用户更好更快的使用模块，论坛维护了一个[示例](https://community.apicloud.com/bbs/thread-109881-1-1.html)，示例中包含示例代码、知识点讲解、注意事项等，供您参考。


# **模块概述**

某些 App 具有打开某一页面即可默认弹出键盘的功能，如某些登陆授权、评论页面。但是一个纯 html 的输入框标签，无法实现这一功能。为满足 APICloud 平台开发者对这一功能的需求，特推出了 UIInput 模块。

UIInput 是一个输入框模块，开发者可通过配置相应参数来控制输入框自动获取焦点，并弹出键盘。同普通的 UI 类的模块一样，本模块也可通过 rect 来设置其位置和大小，通过 styles参数设置其样式。为增强输入框功能，模块开放了 keyboardType 参数，开发者可通过设置该参数来控制其键盘类型。

模块效果图如下：

<img src="https://docs.apicloud.com/img/docImage/module-doc-img/layout/UIInput/UIInput1.PNG" width=400 />

***本模块源码已开源，地址为：https://github.com/apicloudcom/UIInput***

**注意：**

1，在 iOS 上如果 open 窗口时候加了延迟，则该模块被打开时即便 autoFocus 为 true 也不会弹出键盘，会出现弹出键盘然后又缩回去的现象。该问题的解决方法是去掉延迟；

2，由于输入法的关系，当 autoFocus 为 true 时部分 android 机型上默认弹不出键盘

<div id="open"></div>

# **open**

打开输入框，**注意：调用 open 接口的元素，不能加 tapmode 属性**

open({params}, callback(ret))

## params

rect：

- 类型：JSON 对象
- 描述：（可选项）模块的位置及尺寸
- 内部字段：

```js
{
    x: 0,   //（可选项）数字类型；模块左上角的 x 坐标（相对于所属的 Window 或 Frame）；默认：0
    y: 0,   //（可选项）数字类型；模块左上角的 y 坐标（相对于所属的 Window 或 Frame）；默认：0
    w: 320, //（可选项）数字类型；模块的宽度；默认：所属的 Window 或 Frame 的宽度
    h: 40   //（可选项）数字类型；模块的高度；默认：40
}
```

styles：

- 类型：JSON 对象
- 描述：（可选项）模块各部分的样式
- 内部字段：

```js
{
    bgColor: '#fff',        //（可选项）字符串类型；输入框的背景色，支持 rgb、rgba、#；默认：'#fff'
    size: 14,               //（可选项）数字类型；输入框的文字大小；默认：14
    color: '#000',          //（可选项）字符串类型；输入框内的字体颜色，支持 rgb、rgba、#；默认：'#000'
    placeholder: {
        color: '#ccc'       //（可选项）字符串类型；输入框占位文字的颜色；默认：'#ccc'
    }
}
```

maxRows：

- 类型：数字
- 描述：（可选项）支持显示最大行数，文本内容超过此行数时，上下滚动显示。是否支持换行，传大于1的数时表示支持，**注意：取值大于1（多行显示时），不触发 search 事件回调**
- 默认值：1

maxStringLength：

- 类型：数字
- 描述：（可选项）输入框允许输入的最大字符串长度
- 默认值：无限制

autoFocus：

- 类型：布尔
- 描述：（可选项）打开时是否弹出键盘
- 默认值：true

placeholder：

- 类型：字符串
- 描述：（可选项）输入框的占位提示文本

keyboardType:

- 类型：字符串
- 描述：（可选项）输入框获取焦点时，弹出的键盘类型；
- 默认值：'default'
- 取值范围：
    - default（默认键盘）
    - number（数字键盘）
    - search（搜索键盘，Android只有在单行模式下支持）
    - next（下一项，Android只有在单行模式下支持）
    - send（发送，Android只有在单行模式下支持）
    - done（完成，Android只有在单行模式下支持）

alignment:

- 类型：字符串
- 描述：（可选项）文本对齐方式
- 默认值：'left'
- 取值范围：
    - left（居左对齐）
    - center（居中对齐）
    - right（居右对齐）

isCenterVertical:

- 类型：布尔类型
- 描述：输入文本是否上下居中
- 默认：true

inputType:

- 类型：字符串
- 描述：(可选项) 判断输入框输入的是密码还是文字  
- 默认值：'text'
- 取值范围：
     - password：(密码) 仅当maxRows = 1时支持,
     - text：(文字)

fixedOn：

- 类型：字符串类型
- 描述：（可选项）模块视图添加到指定 frame 的名字（只指 frame，传 window 无效）
- 默认：模块依附于当前 window

fixed:

- 类型：布尔
- 描述：（可选项）模块是否随所属 window 或 frame 滚动
- 默认值：true（不随之滚动）

## callback(ret)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
    id:1,                          //数字类型；输入框的id
    eventType: 'show'              //字符串类型；交互事件类型，
                                   //取值范围：
                                   //show（模块打开成功）
                                   //change（输入框内容改变）
                                   //search（点击键盘的搜索按钮）
                                   //send（点击键盘的发送按钮，暂仅支持ios平台）
                                   //done（点击键盘的确定按钮，暂仅支持ios平台）
}
```

## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.open({
	rect: {
		x: 0,
		y: 0,
		w: api.winWidth,
		h: 40
	},
	styles: {
		bgColor: '#fff',
		size: 14,
		color: '#000',
		placeholder: {
			color: '#ccc'
		}
	},
	autoFocus: false,
	maxRows: 4,
	placeholder: '这是一个输入框',
	keyboardType: 'number',
	fixedOn: api.frameName
}, function(ret) {
	if (ret.eventType == 'change') {
    } else {
        alert(JSON.stringify(ret));
    }
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="resetPosition"></div>

# **resetPosition**

重设输入框的位置

resetPosition({params})

## params


id：

- 类型：数字类型
- 描述：需要设置的输入框id

position：

- 类型：JSON 对象
- 描述：（可选项）模块的位置
- 内部字段：

```js
{
    x: 0,   //（可选项）数字类型；模块左上角的 x 坐标（相对于所属的 Window 或 Frame）；默认：0
    y: 0,   //（可选项）数字类型；模块左上角的 y 坐标（相对于所属的 Window 或 Frame）；默认：0
}
```

## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.resetPosition({
	position: {
		x: 100,
		y: 100
	},
	id:2
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.8及更高版本


<div id="close"></div>

# **close**

关闭输入框

close({params})

## **Params**

id：

- 类型：数字类型
- 描述：需要关闭的输入框id


## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.close({
	id:0
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="show"></div>

# **show**

显示输入框

show({params})

## Params

id：

- 类型：数字类型
- 描述：需要展示的输入框id


## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.show({
	id:0
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="hide"></div>

# **hide**

隐藏输入框

hide({params})

## Params

id：

- 类型：数字类型
- 描述：需要隐藏的输入框id


## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.hide({
	id:0
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="value"></div>

# **value**

获取或设置输入框的内容

value({params}, callback(ret))

## params


id：

- 类型：数字类型
- 描述：输入框id

msg：

- 类型：字符串
- 描述：（可选项）输入框的内容，若不传则返回输入框的值

## callback(ret)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
    msg: ''              //字符串类型；输入框当前内容文本
}
```

## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.value({
	msg: '设置输入框的值'
});

UIInput.value(function(ret) {
	if (ret) {
		alert(JSON.stringify(ret));
	}
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="insertValue"></div>

# **insertValue**

向输入框的指定位置插入内容

insertValue({params})

## params

id：

- 类型：数字类型
- 描述：输入框id

index：

- 类型：数字
- 描述：（可选项）插入内容的起始位置。**注意：中文，全角符号均占一个字符长度；索引从0开始，0表示插入到最前面，1表示插入到第一个字符后面，2表示插入到第二个字符后面，以此类推。**
- 默认值：当前输入框的值的长度

msg：

- 类型：字符串
- 描述：（可选项）要插入的内容
- 默认值：''

## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.insertValue({
	index: 10,
	msg: '这里是插入的字符串'
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="popupKeyboard"></div>

# **popupKeyboard**

弹出键盘

popupKeyboard({params})

## Params

id：

- 类型：数字类型
- 描述：输入框id


## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.popupKeyboard({
	id:0
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="closeKeyboard"></div>

# **closeKeyboard**

收起键盘

closeKeyboard({params})


## Params

id：

- 类型：数字类型
- 描述：输入框id


## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.closeKeyboard({
	id:0
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="addEventListener"></div>

# **addEventListener**

事件监听

addEventListener({params}, callback(ret))

## params

id：

- 类型：数字类型
- 描述：输入框id

name：

- 类型：字符串
- 描述：监听的事件类型
- 取值范围：
   - becomeFirstResponder（输入框获得焦点事件）
   - resignFirstResponder（输入框失去焦点事件）

## callback(ret)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
      keyboardHeight:216     //数字类型；本参数仅当当 name 为 becomeFirstResponder 时有效，表示弹出的键盘高度
}
```

## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.addEventListener({
	name: 'resignFirstResponder'
}, function() {
	alert("输入框失去焦点！");
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本



<div id="getSelectedRange"></div>

# **getSelectedRange**

获取当前光标所在位置

getSelectedRange({params},callback(ret))


## params

id：

- 类型：数字类型
- 描述：输入框id

## callback(ret)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
      location:0,    //数字类型；光标位置
}
```

## 示例代码

```js
var UIInput = api.require('UIInput');
UIInput.getSelectedRange({
 id: 0
}, function(ret) {
 alert(JSON.stringify(ret));
});
```

## 可用性

iOS系统，Android系统

可提供的1.0.9及更高版本
