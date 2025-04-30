import 'package:LoyaltyWallet/navbar.dart';
import 'package:LoyaltyWallet/onboarding/onboarding_name.dart';
import 'package:LoyaltyWallet/providers/account_provider.dart';
import 'package:LoyaltyWallet/providers/fidelity_cards_provider.dart';
import 'package:LoyaltyWallet/utils/vars.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnboardingCode extends StatefulWidget {
  const OnboardingCode({super.key});

  @override
  State<OnboardingCode> createState() => _OnboardingCodeState();
}

class _OnboardingCodeState extends State<OnboardingCode> {
  TextEditingController otpController = TextEditingController();
  String testCode = "1234"; // Default test code
  bool hasGeneratedCode = false;

  @override
  void initState() {
    super.initState();
    otpController.addListener(_onOtpChanged);
    
    if (kIsWeb) {
      // Generate a random 4-digit test code for web
      generateTestCode();
    }
  }

  void generateTestCode() {
    if (!hasGeneratedCode) {
      // For demo purposes, use a simple code
      setState(() {
        testCode = "1234";
        hasGeneratedCode = true;
      });
    }
  }

  @override
  void dispose() {
    otpController.removeListener(_onOtpChanged);
    otpController.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    final otp = otpController.text;
    final cards = Provider.of<FidelityCardsProvider>(context, listen: false);
    final auth = Provider.of<AccountProvider>(context, listen: false);
    
    if (otp.length == 4) {
      // For web, accept the test code
      if (kIsWeb && otp == testCode) {
        proceedWithSuccessfulVerification(auth, cards);
      } else {
        auth.verifyCode(otp).then((_) {
          if (auth.errorMessage.isEmpty) {
            proceedWithSuccessfulVerification(auth, cards);
          }
        });
      }
    } else {
      auth.setError('');
    }
  }
  
  void proceedWithSuccessfulVerification(AccountProvider auth, FidelityCardsProvider cards) {
    if (auth.newClient) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingName()),
      );
    } else {
      cards.fetchFidelityCards(auth.token).then((_) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
            'finishedOnboarding', true); // Set onboarding finished
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const NavBar(pageIndex: 0)),
        );
      });
    }
  }

  void _continueWithCode() {
    if (otpController.text.isEmpty && kIsWeb) {
      // If no code entered and on web, auto-fill the test code
      otpController.text = testCode;
    }
    _onOtpChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(builder: (context, auth, _) {
      return Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(
                                context,
                              );
                            },
                            child: const Icon(Icons.arrow_back_ios_new),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).shadowColor,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(15.0),
                        child: Icon(
                          Icons.pin_rounded,
                          size: 30,
                          color: darkGrey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      AppLocalizations.of(context)!.enter_received_code,
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'SFProRounded',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    
                    // Show different message for web
                    kIsWeb 
                      ? Row(
                          children: [
                            Text(
                              "Use test code: $testCode",
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'SFProRounded',
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.info_outline, size: 16),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Test Mode"),
                                    content: Text("On web, we're using a test code instead of SMS verification. You can enter the test code manually or click 'Continue' to proceed automatically."),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("OK"),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      : Text(
                          AppLocalizations.of(context)!.sent_verification_code_sms,
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'SFProRounded',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 25),
                      child: TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        maxLength: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Theme.of(context).shadowColor,
                          hintText:
                              AppLocalizations.of(context)!.onboarding_otp_hint,
                          hintStyle: const TextStyle(
                              fontSize: 18, fontFamily: 'UberMoveMedium'),
                          counterText: '',
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'UberMoveMedium',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.errorMessage,
                              style: const TextStyle(
                                fontSize: 17,
                                fontFamily: 'SFProDisplay',
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                            if (kIsWeb)
                              TextButton(
                                onPressed: () {
                                  otpController.text = testCode;
                                  _onOtpChanged();
                                },
                                child: Text(
                                  "Auto-fill test code",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'SFProDisplay',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                  child: GestureDetector(
                    onTap: _continueWithCode,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: blitzPurple,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(13.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            !auth.loading
                                ? Text(
                                    AppLocalizations.of(context)!
                                        .continue_button,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'SFProRounded',
                                    ),
                                  )
                                : const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
