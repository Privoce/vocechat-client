// UI constants
const double barHeight = 56;

// Enums
enum ChatType { channel, dm }

enum LoginType { password, magiclink }

/// All types that can be sent from TextField widget, including cancelling.
///
/// Each type corresponds to an API.
/// Markdown not included as it is currently not supported by phones according
/// to development plan.
enum SendType { normal, file, edit, reply, audio, cancel }

enum MsgSendStatus { fail, success, sending, readyToSend }

enum LoadingStatus { loading, success, disconnected }

enum SseStatus { init, connecting, successful, disconnected }

enum TokenStatus { init, connecting, successful, unauthorized, disconnected }

enum ButtonStatus { normal, inProgress, success, error }

typedef LoadingAware = Future<void> Function(LoadingStatus status);
typedef SseAware = Future<void> Function(SseStatus status);
typedef TokenAware = Future<void> Function(TokenStatus status);

/// [MsgContentType] is consistant with server definition.
/// Original String consts are defined separately.
enum MsgContentType { text, markdown, file, audio, archive }

/// [MsgDetailType] is consistant with server definition.
enum MsgDetailType { normal, reaction, reply }

const typeText = "text/plain";
const typeMarkdown = "text/markdown";
const typeFile = "vocechat/file";
const typeArchive = "vocechat/archive";
const typeAudio = "vocechat/audio";

/// Email RegEx from https://www.w3.org/TR/2012/WD-html-markup-20120329/input.email.html
// const emailRegEx =
//     r"^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$";
// const pswdRegEx = r"^[a-zA-Z0-9]{6}$";
const urlRegEx =
    r"[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)";

const List<String> audioExts = [
  "mp3",
  "wav",
  "aac",
  "wma",
  "amr",
  "ogg",
  "midi"
];
const List<String> imageExts = [
  "jpg",
  "png",
  "gif",
  "webp",
  "tiff",
  "psd",
  "raw",
  "bmp",
  "heif",
  "indd",
  "jpeg",
  "svg"
];

const List<String> videoExts = [
  "webm",
  "mkv",
  "flv",
  "avi",
  "mov",
  "qt",
  "wmv",
  "rm",
  "rmvb",
  "mp4",
  "m4p",
  "m4v",
  "mpeg",
  "flv"
];

const List<String> codeExts = [
  "c",
  "class",
  "cpp",
  "cs",
  "dtd",
  "fla",
  "h",
  "java",
  "lua",
  "m",
  "pl",
  "py",
  "sh",
  "sln",
  "swift",
  "vb",
  "json"
];

const useCircleAvatar = true;
