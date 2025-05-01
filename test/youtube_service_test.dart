import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_downloader/services/youtube_service.dart';

void main() {
  group('YoutubeService Tests', () {
    test('URL Validation - Valid YouTube URLs', () {
      // Test various valid YouTube URL formats
      expect(YoutubeService.isValidYoutubeUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isTrue);
      expect(YoutubeService.isValidYoutubeUrl('https://youtu.be/dQw4w9WgXcQ'), isTrue);
      expect(YoutubeService.isValidYoutubeUrl('https://m.youtube.com/watch?v=dQw4w9WgXcQ'), isTrue);
    });

    test('URL Validation - Invalid YouTube URLs', () {
      // Test various invalid URLs
      expect(YoutubeService.isValidYoutubeUrl(''), isFalse);
      expect(YoutubeService.isValidYoutubeUrl('not a url'), isFalse);
      expect(YoutubeService.isValidYoutubeUrl('https://example.com'), isFalse);
      expect(YoutubeService.isValidYoutubeUrl('youtube'), isFalse);
    });

    // Integration tests that require actual network calls
    // These should typically be run in a separate group and can be skipped in CI environment
    group('Integration Tests', () {
      test('Successful Video Metadata Load (Happy Path)', () async {
        // This is an integration test that makes an actual network call
        // You might want to skip this in CI environments

        // Use a known valid YouTube video URL
        const validUrl = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'; // Never Gonna Give You Up

        try {
          final videoInfo = await YoutubeService.getVideoInfo(validUrl);

          // Verify basic properties
          expect(videoInfo.id, isNotEmpty);
          expect(videoInfo.title, isNotEmpty);
          expect(videoInfo.author, isNotEmpty);
          expect(videoInfo.thumbnailUrl, isNotEmpty);
          expect(videoInfo.duration, isA<Duration>());

          // Verify we have some streams
          expect(videoInfo.hasAudioStreams || videoInfo.hasVideoStreams, isTrue);

        } catch (e) {
          // If test fails due to network issues, print helpful message
          fail('Test failed, possibly due to network issues: $e');
        }
      }, skip: false); // Set to true if you want to skip this test in CI

      test('Crash Handling - Invalid Video URL', () async {
        // This test verifies that invalid video IDs cause appropriate exceptions
        const invalidUrl = 'https://www.youtube.com/watch?v=invalid_video_id_123';

        // We expect getVideoInfo to throw an exception for invalid URL
        expect(() async => await YoutubeService.getVideoInfo(invalidUrl), throwsException);
      }, skip: false); // Set to true if you want to skip this test in CI
    });
  });
}