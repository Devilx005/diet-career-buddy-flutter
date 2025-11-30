import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'gemini_service.dart';

class JobsDashboard extends StatefulWidget {
  const JobsDashboard({super.key});

  @override
  State<JobsDashboard> createState() => _JobsDashboardState();
}

class _JobsDashboardState extends State<JobsDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _jobs = [];
  Map<String, dynamic>? _selectedJob;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _searchJobs() async {
    if (_searchController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter job title and location';
        _jobs = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _jobs = [];
      _selectedJob = null;
    });

    final role = _searchController.text.trim();
    final location = _locationController.text.trim();

    final liveJobs = await GeminiService.getLinkedInJobs(role, location);

    setState(() {
      _isLoading = false;
      if (liveJobs.isEmpty) {
        _errorMessage = 'No jobs found. Try different keywords!';
      } else {
        _jobs = liveJobs;
        _selectedJob = liveJobs.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canPop = Navigator.canPop(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Jobs',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            return Column(
              children: [
                _buildSearchInput(isMobile),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildLocationInput(isMobile)),
                    const SizedBox(width: 12),
                    _buildSearchButton(isMobile),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: _buildSearchInput(isMobile)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildLocationInput(isMobile)),
              const SizedBox(width: 12),
              _buildSearchButton(isMobile),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchInput(bool isMobile) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 14 : 15,
        ),
        decoration: InputDecoration(
          hintText: isMobile ? 'Job title or company' : 'Search job titles or companies',
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isMobile ? 13 : 14,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInput(bool isMobile) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.5),
      ),
      child: TextField(
        controller: _locationController,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 14 : 15,
        ),
        decoration: InputDecoration(
          hintText: isMobile ? 'Location' : 'City or region',
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isMobile ? 13 : 14,
          ),
          prefixIcon: const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton(bool isMobile) {
    return Container(
      height: 48,
      width: isMobile ? 100 : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _searchJobs,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Search',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 14 : 15,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Finding jobs...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_off,
                size: 64,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      );
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 64,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Search for jobs',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter job title and location',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return _buildJobCardMobile(job);
      },
    );
  }

  Widget _buildDesktopLayout() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            color: Color(0xFF2563EB),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_errorMessage != null || _jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 64,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Search for jobs to get started',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D).withOpacity(0.3),
              border: Border(
                right: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '${_jobs.length} jobs found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _jobs.length,
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      final isSelected = _selectedJob == job;
                      return _buildJobListItem(job, isSelected);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _selectedJob != null
              ? _buildJobDetails(_selectedJob!)
              : Center(
            child: Text(
              'Select a job to view details',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobListItem(Map<String, dynamic> job, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2563EB).withOpacity(0.1) : null,
        border: Border(
          left: BorderSide(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            width: 3,
          ),
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedJob = job;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job['title'] ?? 'Job Title',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  job['company'] ?? 'Company',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      job['location'] ?? 'Location',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSmallTag(job['type'] ?? 'Full-time'),
                    const SizedBox(width: 8),
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      job['posted'] ?? 'Recently',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJobDetails(Map<String, dynamic> job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job['title'] ?? 'Job Title',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job['company'] ?? 'Company',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          job['location'] ?? 'Location',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetaItem(Icons.work_outline, job['type'] ?? 'Full-time'),
              _buildMetaItem(Icons.schedule, job['posted'] ?? 'Recently'),
              if (job['salary'] != 'Not specified')
                _buildMetaItem(Icons.payments_outlined, job['salary'] ?? ''),
            ],
          ),
          const SizedBox(height: 32),
          Divider(color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 32),
          const Text(
            'About the job',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            job['description'] ?? 'No description available',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 40),
          if (job['applyLink'] != null && job['applyLink'].isNotEmpty)
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final url = Uri.parse(job['applyLink']);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Apply on company website',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJobCardMobile(Map<String, dynamic> job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailsScreen(job: job),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job['title'] ?? 'Job Title',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  job['company'] ?? 'Company',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      job['location'] ?? 'Location',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildSmallTag(job['type'] ?? 'Full-time'),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      job['posted'] ?? 'Recently',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Mobile Job Details Screen
class JobDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Job Details', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job['title'] ?? 'Job Title',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['company'] ?? 'Company',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            job['location'] ?? 'Location',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildTag(job['type'] ?? 'Full-time'),
                _buildTag(job['posted'] ?? 'Recently'),
                if (job['salary'] != 'Not specified') _buildTag(job['salary'] ?? ''),
              ],
            ),
            const SizedBox(height: 28),
            Divider(color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 28),
            const Text(
              'About the job',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              job['description'] ?? 'No description available',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 36),
            if (job['applyLink'] != null && job['applyLink'].isNotEmpty)
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final url = Uri.parse(job['applyLink']);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Apply on company website',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
