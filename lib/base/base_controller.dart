import 'base_notifier.dart';

/*
* 控制器基类
* @author Andy Hou
* @Time 2022/5/29 15:27
*/

abstract class BaseController<V> extends ValueChangeNotifier<V> {
  BaseController(V v) : super(v);
}

/*
* 控制器基类-表单
* @author Andy Hou
* @Time 2022/5/29 15:27
*/
abstract class BaseControllerMap<K, V> extends MapValueChangeNotifier<K, V> {
  BaseControllerMap(Map<K, V> v) : super(v);
}

/*
* 控制器基类-集合
* @author Andy Hou
* @Time 2022/5/29 15:27
*/
abstract class BaseControllerList<V> extends ListValueChangeNotifier<V> {
  BaseControllerList(List<V> v) : super(v);
}

/*
* 测试ChatPage与ChatService传递参数
* @author Andy Hou
* @Time 2022/5/29 15:27
*/
// class SendMessageController extends BaseController<SendType> {
//   SendMessageController._init({
//     SendType initialValue = SendType.normal,
//   }) : super(initialValue);
//
//   static SendMessageController? _instance;
//
//   factory SendMessageController() =>
//       _instance ??= SendMessageController._init();
//   //获取当前展示状态
//   SendType get showSendType => value;
//
//   void changeSendType(type) {
//     setValue(type);
//   }
//
//   // //清空当前角标内容
//   // void clear() => setValue("");
// }
