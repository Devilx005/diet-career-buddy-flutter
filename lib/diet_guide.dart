import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'gemini_service.dart';

class DIETGuide extends StatefulWidget {
  @override
  _DIETGuideState createState() => _DIETGuideState();
}

class _DIETGuideState extends State<DIETGuide> {
  String _content = '';
  bool _isLoading = false;

  Future<void> _generateContent() async {
    setState(() {
      _isLoading = true;
      _content = '';
    });

    await GeminiService.getDIETGuideStreaming((chunk) {
      setState(() {
        _content = chunk;
      });
    });

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎓 DIET College Guide'),
        backgroundColor: Colors.purple,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // College Header Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏛️ Dnyanshree Institute of Engineering & Technology',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.white70),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Satara, Maharashtra | Est. 2012',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _launchURL('https://dnyanshree.edu.in'),
                    icon: Icon(Icons.language, size: 18),
                    label: Text('Visit Official Website'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Quick Info Cards
            Row(
              children: [
                Expanded(
                  child: _infoCard('📚', 'B.Tech', '5 Branches', Colors.blue),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _infoCard('🎓', 'Diploma', '2 Programs', Colors.orange),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoCard('💼', 'Placements', '60-80%', Colors.green),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _infoCard('💰', 'Highest PKG', '₹8.55 LPA', Colors.teal),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Courses Section
            _sectionTitle('📚 Courses Offered'),
            _courseCard('B.Tech Programs', [
              'Computer Science Engineering (60-90 seats)',
              'Mechanical Engineering (60-90 seats)',
              'Civil Engineering (30-60 seats)',
              'Electrical Engineering (30-60 seats)',
              'E&TC Engineering (30-60 seats)',
            ]),
            SizedBox(height: 12),
            _courseCard('Diploma Programs', [
              'Electronics & Communication (30 seats)',
              'Mechanical Engineering (45 seats)',
            ]),
            SizedBox(height: 20),

            // Placements Section
            _sectionTitle('💼 Placement Statistics 2021-22'),
            _placementTable(),
            SizedBox(height: 12),
            _infoBox('🏢 Top Recruiters: TCS, Infosys, Wipro, Mahindra, Capgemini, Hettich'),
            SizedBox(height: 20),

            // AI Career Guide Button
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateContent,
                child: Text(_isLoading ? '⏳ Generating...' : '🤖 Get AI Career Guidance'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 20),

            // AI Response
            if (_content.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  _content,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String emoji, String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
      ),
    );
  }

  Widget _courseCard(String title, List<String> courses) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...courses.map((course) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text(course, style: TextStyle(fontSize: 14))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _placementTable() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        border: TableBorder.all(color: Colors.grey.withOpacity(0.3)),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2)),
            children: [
              _tableCell('Branch', isHeader: true),
              _tableCell('Highest', isHeader: true),
              _tableCell('Average', isHeader: true),
            ],
          ),
          _tableDataRow('Computer', '₹7.5L', '₹4.5L'),
          _tableDataRow('Mechanical', '₹8.55L', '₹1.74L'),
          _tableDataRow('Civil', '₹3.6L', '₹1.2L'),
          _tableDataRow('Electrical', '₹4L', '₹2L'),
          _tableDataRow('E&TC', '₹5L', '₹1.2L'),
        ],
      ),
    );
  }

  TableRow _tableDataRow(String branch, String highest, String average) {
    return TableRow(
      children: [
        _tableCell(branch),
        _tableCell(highest),
        _tableCell(average),
      ],
    );
  }

  Widget _tableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.purple : Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 14)),
    );
  }
}
