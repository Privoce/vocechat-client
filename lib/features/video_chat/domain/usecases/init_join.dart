import 'package:vocechat_client/core/resources/data_state.dart';
import 'package:vocechat_client/core/usecase/usecase.dart';
import 'package:vocechat_client/features/video_chat/domain/entities/agora_basic_info.dart';
import 'package:vocechat_client/features/video_chat/domain/repository/agora_repo.dart';

class AgoraInitJoinParams {
  int? uid;
  int? gid;

  AgoraInitJoinParams({this.uid, this.gid}) {
    assert((uid == null && gid != null) || (uid != null && gid == null));
  }
}

class InitJoinAgoraUseCase
    extends UseCase<DataState<AgoraBasicInfoEntity>, AgoraInitJoinParams> {
  final AgoraRepository _repository;

  InitJoinAgoraUseCase(this._repository);

  @override
  Future<DataState<AgoraBasicInfoEntity>> call(
      AgoraInitJoinParams params) async {
    return _repository.getAgoraBasicInfo(uid: params.uid, gid: params.gid);
  }
}
