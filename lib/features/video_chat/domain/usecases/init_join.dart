import 'package:vocechat_client/core/resources/data_state.dart';
import 'package:vocechat_client/core/usecase/usecase.dart';
import 'package:vocechat_client/features/video_chat/domain/entities/agora_basic_info.dart';
import 'package:vocechat_client/features/video_chat/domain/repository/agora_repo.dart';

class InitJoinAgoraUseCase
    extends UseCase<DataState<AgoraBasicInfoEntity>, void> {
  final AgoraRepository _repository;

  InitJoinAgoraUseCase(this._repository);

  @override
  Future<DataState<AgoraBasicInfoEntity>> call({void params}) {
    return _repository.getAgoraBasicInfo();
  }
}
