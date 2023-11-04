import 'package:vocechat_client/core/resources/data_state.dart';
import 'package:vocechat_client/core/usecase/usecase.dart';
import 'package:vocechat_client/features/video_chat/domain/entities/agora_basic_info.dart';
import 'package:vocechat_client/features/video_chat/domain/repository/agora_repo.dart';

class AgoraInitParams {
  int? uid;
  int? gid;
  bool isVideoCall;

  AgoraInitParams({this.uid, this.gid, required this.isVideoCall}) {
    assert((uid == null && gid != null) || (uid != null && gid == null));
  }
}

class AgoraInitUseCase
    extends UseCase<DataState<AgoraBasicInfoEntity>, AgoraInitParams> {
  final AgoraRepository _repository;

  AgoraInitUseCase(this._repository);

  @override
  Future<DataState<AgoraBasicInfoEntity>> call(AgoraInitParams params) async {
    return _repository.getAgoraBasicInfo(uid: params.uid, gid: params.gid);
  }
}

// class AgoraJoin 