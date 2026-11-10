import 'package:flutter/material.dart';

abstract class Languages {
  static Languages? of(BuildContext context) {
    return Localizations.of<Languages>(context, Languages);
  }

  String get txtSettings;

  String get txtMusic;

  String get txtRate;

  String get txtShare;

  String get txtSendFeedback;

  String get txtPrivacyPolicy;

  String get txtKidsGamesFeedbackAndroid;

  String get txtKidsGamesFeedbackIOS;

  String get txtKidsGames;

  String get txtShareDesc;

  String get txtOK;

  String get txtCancel;

  String get txtYes;

  String get txtNo;

  String get txtAreYouSureYouWantToExit;

  String get txtForGrownUps;

  String get txtToAccessEnterNumbers;

  String get txtAwesome;

  String get txtLevel;

  String get txtQuestion;

  String get txtPlayAgain;

  String get txtPlayNext;

  String get txtGoToHome;

  String get txtYouHaveSuccessfullyCompleted;

  String get txtYouHaveFailed;

  String get txtTryAgainNow;

  String get txtNext;

  String get txtLevel_;

  String get txtAreYouSureYouWantToExitGame;


  String get txtLanguage;

  /// Settings: the picture behind every screen.
  String get txtBackground;

  /// Name of a background choice (0-based).
  String backgroundName(int index);

  /// Home screen title above the category cards.
  String get txtCategories;

  /// Number of quizzes in a category, e.g. "6 quizzes".
  String quizCount(int count);

  // Bottom navigation.
  String get txtPlay;
  String get txtTreats;
  String get txtProgress;

  // Rewards.
  String get txtMyTreats;
  String get txtYouWonGift;
  String get txtTapToOpen;
  String get txtYummy;
  String get txtLevelUp;
  String get txtStars;
  String get txtQuizzesDone;
  String get txtTreatsCollected;
  String get txtEarnTreatsHint;
  String txtYouGot(String treat);
  String txtGiftsWaiting(int count);
  String txtStarsToNextGift(int count);

  // About / contact.
  String get txtContactUs;
  String get txtDevelopedBy;

  // Accessibility: settings.
  String get txtAccessibility;
  String get txtAudioQuiz;
  String get txtAudioQuizDesc;
  String get txtReadAloud;
  String get txtReadAloudDesc;
  String get txtVoiceSpeed;
  String get txtSlow;
  String get txtNormal;
  String get txtFast;
  String get txtVoiceVolume;
  String get txtLow;
  String get txtMedium;
  String get txtHigh;
  String get txtTestVoice;
  String get txtVoiceSample;
  String get txtNoAmharicVoice;
  String get txtAudioQuizTurnedOn;
  String get txtTelegram;
  String get txtEmail;
  String get txtCall;
  String get txtPhotoCredits;
  String get txtAppVoice;
  String get txtAppVoiceDesc;
  String get txtKeyboardHelp;

  // Accessibility: quiz narration and screen-reader labels.
  String get txtListen;
  String get txtTapToHearAgain;
  String get txtWhatIsThis;
  String get txtWhichOne;
  String get txtHint;
  String get txtNoMoreHints;
  String get txtNextQuestion;
  String get txtSwitchToAudio;
  String get txtSwitchToPictures;
  String get txtQuestionPicture;
  String a11yQuestionOf(int number, int total);
  String a11yOption(int number, String name);
  String a11yTapAgainToChoose(int number, String name);
  String a11yCorrect(String answer);
  String a11yWrong(String chosen, String answer);
  String a11yStartsWith(String letter);
  String a11yNotThese(String a, String b);
  String a11yQuizIntro(String quiz);
  String a11yResult(int correct, int total);
  String a11yStars(int count);
  String a11yProgress(int done, int total);

  // Forced update screen.
  String get txtUpdateTitle;
  String get txtUpdateMessage;
  String get txtUpdateNow;
}
