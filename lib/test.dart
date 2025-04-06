class _BusesState extends State<Buses> {
  // ...
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _fromFocus.addListener(() {
      if (!_fromFocus.hasFocus) {
        FocusScope.of(context).requestFocus(_toFocus);
      }
    });
    _toFocus.addListener(() {
      if (!_toFocus.hasFocus) {
        FocusScope.of(context).requestFocus(_fromFocus);
      }
    });
  }

  @override
  void dispose() {
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  // ...
}