/*
* 草稿控制器
* @author Andy Hou
* @Time 2022/5/29 15:27
*/
import 'package:flutter/cupertino.dart';

import 'base_controller.dart';

class DraftController extends ChangeNotifier {
  String value = '';
  //获取当前展示状态
  String get showDraft => value;
  changeValue(newValue) {
    value = newValue;
  }
  //清空当前角标内容

}
