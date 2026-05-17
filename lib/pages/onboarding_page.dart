// import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluidify_mobile/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:fluidify_mobile/const/fluidy_const.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fluidify_mobile/models/onboarding.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  List<Onboarding> items = [
    Onboarding(
        title: "Belajar Fluida Jadi Seru!",
        description: "Belajar konsep fluida dari kejadian nyata di sekitarmu.",
        imageSrc: "assets/img/onboarding/fluidy_seeing.png"),
    Onboarding(
        title: "Tingkatkan Penalaran Ilmiah Kamu!",
        description: "Latih pemahamanmu dengan soal aplikatif sederhana.",
        imageSrc: "assets/img/onboarding/fluidy_writing.png"),
    Onboarding(
        title: "Berpikir secara saintis!",
        description:
            "Disini kamu akan belajar dan berpikir seperti seorang ilmuwan!",
        imageSrc: "assets/img/onboarding/fluidy_teaching.png"),
  ];
  final _pageController = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView.builder(
        itemCount: items.length,
        controller: _pageController,
        onPageChanged: (index) => setState(() {
          isLastPage = index == items.length - 1;
        }),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(
                left: 40, right: 40, top: 60, bottom: 120),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(items[index].imageSrc, height: 300),
                const SizedBox(
                  height: 20,
                ),
                Text(
                  items[index].title,
                  style:
                      fBoldTextStyle.copyWith(fontSize: 28, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    items[index].description,
                    textAlign: TextAlign.center,
                    style: fMediumTextStyle.copyWith(
                        fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: isLastPage
            ? loginBtn()
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _pageController.jumpToPage(items.length - 1);
                    },
                    child: const Text(
                      "Lewati",
                      style: TextStyle(
                          letterSpacing: 3, fontSize: 18, color: Colors.blue),
                    ),
                  ),
                  SmoothPageIndicator(
                      controller: _pageController,
                      count: items.length,
                      onDotClicked: (index) => _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease),
                      effect: const WormEffect(
                        dotHeight: 12,
                        dotWidth: 12,
                        activeDotColor: Colors.blue,
                      )),
                  TextButton(
                    onPressed: () {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease);
                    },
                    child: const Text(
                      "Selanjutnya",
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget loginBtn() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const LoginPage()));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(double.infinity, 55),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Masuk Sekarang",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward),
          ],
        ),
      ),
    );
  }
}
