import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'first_page.dart';
import 'registration_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  List<Map<String, dynamic>> onboardingData = [
    {
      'image': 'assets/image2.png',
      'title': 'Attendance Tracking',
      'description': 'Mark your attendance by scanning QR codes.'
    },
    {
      'image': 'assets/image3.png',
      'title': 'Share the Meal',
      'description': 'Planning to take a meal cut?,\nDon\'t worry, Share your meals with fellow non-hostelers ',
    },
    {
      'image': 'assets/image4.png',
      'title': 'Fee Payment',
      'description': 'Easily pay your hostel fees securely through the app.'
    },
    {
      'image': 'assets/image5.png',
      'title': 'Meal Polling',
      'description': 'Vote for your favorite meals and help decide what\'s on the menu!'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingData.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(onboardingData[index]);
            },
          ),
          Positioned(
            top: 40,
            left: 10,
            child: Theme(
              data: Theme.of(context).copyWith(splashColor: Colors.transparent),
              child: TextButton(
                style: ButtonStyle(overlayColor: MaterialStateProperty.all(Color.fromARGB(4, 0, 0, 0))),
                onPressed: () {
                  if (_currentPageIndex > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.ease,
                    );
                  } else {
                    Navigator.of(context).pushReplacement(PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => FirstPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        var begin = Offset(0.0, -1.0);
                        var end = Offset.zero;
                        var curve = Curves.ease;

                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);

                        return SlideTransition(
                          position: offsetAnimation,
                          child: child,
                        );
                      },
                    ));
                  }
                },
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(fontSize: 15,color: Color(0xFFFBC32C),fontWeight: FontWeight.normal),
                ),
              ),
            ),
          ),
          if (_currentPageIndex < onboardingData.length - 1) // Show "Next" button if not on last page
            Positioned(
              top: 40,
              right: 10,
              child: Theme(
                data: Theme.of(context).copyWith(splashColor: Colors.transparent),
                child: TextButton(
                  style: ButtonStyle(overlayColor: MaterialStateProperty.all(Color.fromARGB(4, 0, 0, 0))),
                  onPressed: () {
                    if (_currentPageIndex < onboardingData.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    }
                  },
                  child: Text(
                    'Next',
                    style: GoogleFonts.inter(fontSize: 15,color: Color(0xFFFBC32C),fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => _buildDot(index: index),
              ),
            ),
          ),
          if (_currentPageIndex ==
              onboardingData.length -
                  1) // "Sign Up" button only on the last page
            Positioned(
              bottom: 125,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: const Color(0xFFFBC32C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(39),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RegistrationScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 107,
                        vertical:
                            10), // Apply the same padding as "Get Started" button
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.nunitoSans(
                        // Apply Google Fonts
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> data) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(data['image'], height: 300),
        const SizedBox(height: 20),
        Text(
          data['title'],
          style: GoogleFonts.nunitoSans(
            // Apply Google Fonts
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Text(
            data['description'],
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              // Apply Google Fonts
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 7,
      width: 7,
      decoration: BoxDecoration(
        color: index == _currentPageIndex
            ? const Color(0xFFFBC32C)
            : const Color.fromARGB(90, 251, 196, 44),
        shape: BoxShape.circle,
      ),
    );
  }
}

