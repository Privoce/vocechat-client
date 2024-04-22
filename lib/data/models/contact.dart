import 'package:floor/floor.dart';
import 'package:vocechat_client/data/enums/contact_status_enum.dart';

@Entity(
  tableName: 'contacts',
  // foreignKeys: ForeignKey(
  // childColumns: ['targetUid'],
  // parentColumns: ['uid'],
  // entity: UserInfo)
)
class Contact {
  @PrimaryKey(autoGenerate: false)
  final int targetUid;

  // info in [ContactInfo] class
  final ContactStatusEnum? status;
  final int? createdAt;
  final int? updatedAt;

  Contact({
    required this.targetUid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  }) : super();
}
