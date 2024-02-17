import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package
import 'registration_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  bool _showButtons = true;

  List<Map<String, dynamic>> onboardingData = [
    {
      'image': 'assets/image2.png',
      'title': 'Title 1',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
    },
    {
      'image': 'assets/image2.png',
      'title': 'Title 2',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
    },
    {
      'image': 'assets/image3.png',
      'title': 'Title 3',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
    },
    {
      'image': 'assets/image2.png',
      'title': 'Title 4',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
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
            left: 20,
            right: 20,
            bottom: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _currentPageIndex > 0
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                        },
                      )
                    : const Opacity(
                        opacity: 0,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          onPressed: null,
                        )),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    onboardingData.length,
                    (index) => _buildDot(index: index),
                  ),
                ),
                _currentPageIndex > 0 &&
                        _currentPageIndex < onboardingData.length - 1
                    ? IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                        },
                      )
                    : const Opacity(
                        opacity: 0,
                        child: IconButton(
                          icon: Icon(Icons.arrow_forward_ios),
                          onPressed: null,
                        )),
              ],
            ),
          ),
          if (_showButtons &&
              _currentPageIndex ==
                  0) // "Get Started" button only on the first page
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
                    setState(() {
                      _showButtons = false;
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    });
                  },
                 
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 10), // Increase button padding
                    child: Text(
                      'Get Started',
                      style: GoogleFonts.nunitoSans( // Apply Google Fonts
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white
                      ),
                    ),
                  ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 107, vertical: 10), // Apply the same padding as "Get Started" button
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.nunitoSans( // Apply Google Fonts
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
          style: GoogleFonts.nunitoSans( // Apply Google Fonts
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
            style: GoogleFonts.nunitoSans( // Apply Google Fonts
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
