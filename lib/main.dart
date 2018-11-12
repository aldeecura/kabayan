import 'dart:async';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:flutter_news/model/news.dart';
import 'package:flutter_news/request/request.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_news/widget/loading_footer.dart';
import 'package:flutter_news/widget/news_item.dart';

void main() => runApp(new KabayanNews());


const appId = 'ca-app-pub-1359002954768604~4974073085';

MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
  keywords: <String>['overseas filipino workers', 'philippines news', 'balita', 'ofw', 'remittance', 'balikbayan box','flutterio', 'beautiful apps'],
  contentUrl: 'https://flutter.io',
  birthday: DateTime.now(),
  childDirected: false,
  designedForFamilies: false,
  gender: MobileAdGender.unknown, // or MobileAdGender.female, MobileAdGender.unknown
  testDevices: <String>[], // Android emulators are considered test devices
);

BannerAd myBanner = BannerAd(
  // Replace the testAdUnitId with an ad unit id from the AdMob dash.
  // https://developers.google.com/admob/android/test-ads
  // https://developers.google.com/admob/ios/test-ads
  adUnitId: 'ca-app-pub-1359002954768604/7818485006', //BannerAd.testAdUnitId,
  size: AdSize.smartBanner,
  targetingInfo: targetingInfo,
  listener: (MobileAdEvent event) {
    print("BannerAd event is $event");
  },
);

InterstitialAd myInterstitial = InterstitialAd(
  // Replace the testAdUnitId with an ad unit id from the AdMob dash.
  // https://developers.google.com/admob/android/test-ads
  // https://developers.google.com/admob/ios/test-ads
  adUnitId: InterstitialAd.testAdUnitId,
  targetingInfo: targetingInfo,
  listener: (MobileAdEvent event) {
    print("InterstitialAd event is $event");
  },
);

class KabayanNews extends StatefulWidget {
  @override
  _KabayanNewsState createState() => _KabayanNewsState();
}

class _KabayanNewsState extends State<KabayanNews> {

  @override
  void initState() {
    FirebaseAdMob.instance.initialize(appId: appId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kabayan',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: HeadLinePage(title: 'Kabayan News'),
    );
  }
}

class HeadLinePage extends StatefulWidget {
  final String title;

  HeadLinePage({Key key, this.title}) : super(key: key);

  @override
  _HeadLinePageState createState() => new _HeadLinePageState();
}

class _HeadLinePageState extends State<HeadLinePage> with SingleTickerProviderStateMixin {

  final List<Tab> newsTabs = <Tab>[
    new Tab(text: 'General'),
    new Tab(text: 'Technology'),
    new Tab(text: 'Business'),
    new Tab(text: 'Entertainment'),
    new Tab(text: 'Sports'),
    new Tab(text: 'Science'),
    new Tab(text: 'Health'),
  ];

  TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: newsTabs.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    myBanner
    // typically this happens well before the ad is shown
      ..load()
      ..show(
        // Positions the banner ad 60 pixels from the bottom of the screen
        anchorOffset: 0.0,
        // Banner Position
        anchorType: AnchorType.bottom,
      );

    return Scaffold(
        appBar: AppBar(title: Text(widget.title), bottom: TabBar(tabs: newsTabs, isScrollable: true, controller: _tabController,)),
        body: TabBarView( controller: _tabController,
            children: newsTabs.map((Tab tab) {
              return HeadLineList(tab.text);
            }).toList()));
  }

}

class HeadLineList extends StatefulWidget {

  final String _category;

  HeadLineList(this._category);


  @override
  _HeadLineListState createState() => _HeadLineListState();
}

class _HeadLineListState extends State<HeadLineList> with AutomaticKeepAliveClientMixin {
  static const int IDLE = 0;
  static const int LOADING = 1;
  static const int ERROR = 3;
  static const int EMPTY = 4;

  int _pageCount = 0;

  int _status = IDLE;
  String _message;

  int _footerStatus = LoadingFooter.IDLE;
  double _lastOffset = 0.0;

  List<News> _articles;

  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  Completer<Null> _completer;

  ScrollController _controller;

  Future _getNews() async {
    _pageCount = 0;
    NewsList news = await NewsApi.getHeadLines(category: widget._category);
    if (!mounted) {
      return;
    }
    _articles = news?.articles;
    if (_completer != null) {
      _completer.complete();
      _completer = null;
    }
    setState(() {
      if ("ok".compareTo(news?.status) != 0) {
        _status = ERROR;
        _message = news?.message;
      } else if (_articles?.isEmpty ?? false) {
        _status = EMPTY;
      } else {
        _pageCount++;
        _status = IDLE;
      }
    });
  }

  Future<Null> _onRefresh() {
    _completer = new Completer<Null>();
    _getNews();
    return _completer.future;
  }

  Future loadMore() async {
    setState(() {
      _footerStatus = LoadingFooter.LOADING;
    });
    NewsList news = await NewsApi.getHeadLines(page: _pageCount, category: widget._category);
    if (!mounted) {
      return;
    }
    setState(() {
      if (news?.articles?.isNotEmpty ?? false) {
        _pageCount++;
      }
      _articles.addAll(news?.articles);
      _footerStatus = LoadingFooter.IDLE;
    });
  }

  @override
  void initState() {
    super.initState();
    _status = LOADING;
    _controller = ScrollController();
    _controller.addListener(() {
      if (_footerStatus == LoadingFooter.IDLE &&
          _controller.offset > _lastOffset &&
          _controller.position.maxScrollExtent - _controller.offset < 100) {
        loadMore();
      }
      _lastOffset = _controller.offset;
    });
    _getNews();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case IDLE:
        return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
                itemCount: _articles.length + 1,
                itemBuilder: (context, index) {
                  if (index == _articles.length) {
                    return LoadingFooter(
                        retry: () {
                          loadMore();
                        },
                        state: _footerStatus);
                  } else {
                    return NewsItem(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => WebviewScaffold(
                                    url: '${_articles[index].url}',
                                    appBar:
                                    AppBar(title: Text("News Detail")),
                                  )));
                        },
                        news: _articles[index]);
                  }
                },
                controller: _controller));
      case LOADING:
        return Center(child: CircularProgressIndicator());
      case ERROR:
        return Center(
            child: Text(_message ??
                "Something is wrong, you might need to reboot your phone."));
      case EMPTY:
        return Center(child: Text("No news is good news!"));
      default:
        return Center(child: Text("Emm..."));
    }
  }

  @override
  bool get wantKeepAlive => true;
}
