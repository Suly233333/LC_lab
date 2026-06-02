/// 本地密钥配置模板。
///
/// 实际开发时复制此文件为 `secrets.dart` 并填入真实密钥；
/// `secrets.dart` 已被加入 `.gitignore`，不会被纳入版本控制。
class Secrets {
  Secrets._();

  /// 智谱 GLM API Key（https://bigmodel.cn）。
  static const String glmApiKey = 'YOUR_GLM_API_KEY_HERE';

  /// 共鸣度匹配使用的模型；建议低成本 flash 档。
  static const String glmResonanceModel = 'glm-4-flash';

  /// 沟通对话使用的模型；建议更强一些以支持人格扮演。
  static const String glmChatModel = 'glm-4-flash';
}
