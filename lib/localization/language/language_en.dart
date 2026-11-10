import 'languages.dart';

class LanguageEn extends Languages {

  @override
  String get txtPrivacyPolicy => "Privacy Policy";

  @override
  String get txtRate => "Rate Us";

  @override
  String get txtSendFeedback => "Send Feedback";

  @override
  String get txtSettings => "Settings";

  @override
  String get txtShare => "Share";

  @override
  String get txtMusic => "Music";

  @override
  String get txtKidsGamesFeedbackAndroid => "Kids Games - Android";

  @override
  String get txtKidsGamesFeedbackIOS => "Kids Games - iOS";

  @override
  String get txtKidsGames => "Kids Games";

  @override
  String get txtShareDesc =>
      "Learn and play with Kaldi! A fun quiz game for kids in English and Amharic.\n\nDownload it free on Google Play:\n";

  @override
  String get txtCancel => "Cancel";

  @override
  String get txtOK => "Ok";

  @override
  String get txtNo => "No";

  @override
  String get txtYes => "Yes";

  @override
  String get txtAreYouSureYouWantToExit => "Are you sure you want to exit?";

  @override
  String get txtForGrownUps => "FOR GROWN-UPS";

  @override
  String get txtToAccessEnterNumbers => "To Access, Please Enter The Numbers";

  @override
  String get txtAwesome => "Awesome!";

  @override
  String get txtGoToHome => "Go To Home";

  @override
  String get txtLevel => "Level";

  @override
  String get txtLevel_ => "Level - ";

  @override
  String get txtNext => "Next";

  @override
  String get txtPlayAgain => "Play Again";

  @override
  String get txtPlayNext => "Play Next";

  @override
  String get txtQuestion => "Question";

  @override
  String get txtTryAgainNow => "Try Again Now!";

  @override
  String get txtYouHaveFailed => "You Have Failed Level - ";

  @override
  String get txtYouHaveSuccessfullyCompleted => "You Have Successfully Completed";

  @override
  String get txtAreYouSureYouWantToExitGame => "Are you sure you want to quit this level?";

  @override
  String get txtLanguage => "Language";

  @override
  String get txtBackground => "Background";

  @override
  String backgroundName(int index) =>
      const ["Cream", "Caramel", "Dark Roast"][index];

  @override
  String get txtCategories => "Categories";

  @override
  String quizCount(int count) => count == 1 ? "1 quiz" : "$count quizzes";

  @override
  String get txtPlay => "Play";

  @override
  String get txtTreats => "Rewards";

  @override
  String get txtProgress => "My Level";

  @override
  String get txtMyTreats => "My Rewards";

  @override
  String get txtYouWonGift => "You won a gift!";

  @override
  String get txtTapToOpen => "Tap to open!";

  @override
  String get txtYummy => "Yummy!";

  @override
  String get txtLevelUp => "Level up!";

  @override
  String get txtStars => "Stars";

  @override
  String get txtQuizzesDone => "Quizzes done";

  @override
  String get txtTreatsCollected => "Rewards collected";

  @override
  String get txtEarnTreatsHint => "Earn stars in quizzes to win yummy rewards!";

  @override
  String txtYouGot(String treat) => "You got $treat!";

  @override
  String txtGiftsWaiting(int count) =>
      count == 1 ? "1 gift is waiting!" : "$count gifts are waiting!";

  @override
  String txtStarsToNextGift(int count) =>
      count == 1 ? "1 more ★ for the next gift" : "$count more ★ for the next gift";

  @override
  String get txtContactUs => "Contact Us";

  @override
  String get txtDevelopedBy => "Made with love by";

  @override
  String get txtAccessibility => "Accessibility";

  @override
  String get txtAudioQuiz => "Audio quiz";

  @override
  String get txtAudioQuizDesc =>
      "For children who can't see the pictures: every question is a spoken riddle with big answer buttons.";

  @override
  String get txtReadAloud => "Read aloud";

  @override
  String get txtReadAloudDesc =>
      "Reads the picture quiz questions and answers aloud.";

  @override
  String get txtVoiceSpeed => "Voice speed";

  @override
  String get txtSlow => "Slow";

  @override
  String get txtNormal => "Normal";

  @override
  String get txtFast => "Fast";

  @override
  String get txtVoiceVolume => "Voice volume";

  @override
  String get txtLow => "Low";

  @override
  String get txtMedium => "Medium";

  @override
  String get txtHigh => "High";

  @override
  String get txtTestVoice => "Test the voice";

  @override
  String get txtVoiceSample => "Hello! I'm Kaldi. Let's play and learn together!";

  @override
  String get txtNoAmharicVoice =>
      "This phone has no Amharic voice yet, so the narrator speaks English. You can add one in the phone's text-to-speech settings.";

  @override
  String get txtAudioQuizTurnedOn =>
      "A screen reader is on, so the audio quiz has been turned on. You can change this in Settings.";

  @override
  String get txtTelegram => "Telegram";

  @override
  String get txtEmail => "Email";

  @override
  String get txtCall => "Call";

  @override
  String get txtPhotoCredits => "Photo credits";

  @override
  String get txtAppVoice => "Kaldi's voice";

  @override
  String get txtAppVoiceDesc =>
      "Turn off if you use a screen reader (TalkBack, VoiceOver, JAWS or NVDA), so only one voice talks.";

  @override
  String get txtKeyboardHelp =>
      "Keys: 1 to 4 choose an answer, H hint, R repeat, N next question, Escape go back.";

  @override
  String get txtListen => "Listen";

  @override
  String get txtTapToHearAgain => "Tap to hear it again";

  @override
  String get txtWhatIsThis => "What is this?";

  @override
  String get txtWhichOne => "Which one is it?";

  @override
  String get txtHint => "Hint";

  @override
  String get txtNoMoreHints => "No more hints. You can do it!";

  @override
  String get txtNextQuestion => "Next question";

  @override
  String get txtSwitchToAudio => "Switch to the audio quiz";

  @override
  String get txtSwitchToPictures => "Switch to the picture quiz";

  @override
  String get txtQuestionPicture => "Question picture";

  @override
  String a11yQuestionOf(int number, int total) =>
      "Question $number of $total.";

  @override
  String a11yOption(int number, String name) => "Number $number: $name.";

  @override
  String a11yTapAgainToChoose(int number, String name) =>
      "Number $number, $name. Tap again to choose it.";

  @override
  String a11yCorrect(String answer) => "Yes! It is $answer. Well done!";

  @override
  String a11yWrong(String chosen, String answer) =>
      "Oops, that was $chosen. The answer is $answer. Good try!";

  @override
  String a11yStartsWith(String letter) => "Its name starts with $letter.";

  @override
  String a11yNotThese(String a, String b) => "It is not $a, and not $b.";

  @override
  String a11yQuizIntro(String quiz) =>
      "$quiz. Listen to each riddle, then choose the answer.";

  @override
  String a11yResult(int correct, int total) =>
      "You got $correct out of $total right.";

  @override
  String a11yStars(int count) => count == 1 ? "1 star" : "$count stars";

  @override
  String a11yProgress(int done, int total) => "$done of $total quizzes done";

  @override
  String get txtUpdateTitle => "Time to update!";

  @override
  String get txtUpdateMessage =>
      "A new version of Kaldi is ready with fixes and new fun. Please update to keep playing.";

  @override
  String get txtUpdateNow => "Update now";
}
