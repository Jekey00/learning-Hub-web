import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/posts/screens/create_post_screen.dart';
import '../../features/reels/screens/reels_screen.dart';
import '../../features/reels/screens/create_reel_screen.dart';
import '../../features/reels/screens/reel_category_choice_screen.dart';
import '../../features/reels/screens/reel_type_choice_screen.dart';
import '../../features/flashcards/screens/flashcard_sets_screen.dart';
import '../../features/flashcards/screens/study_screen.dart';
import '../../features/flashcards/screens/create_flashcard_set_screen.dart';
import '../widgets/main_navigation.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigation(child: child);
        },
        routes: [
          GoRoute(
            path: '/feed',
            builder: (context, state) => const FeedScreen(),
          ),
          GoRoute(
            path: '/reels',
            builder: (context, state) => const ReelCategoryChoiceScreen(),
          ),
          GoRoute(
            path: '/flashcards',
            builder: (context, state) => const FlashcardSetsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/reels/type/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId'];
          return ReelTypeChoiceScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/reels/feed',
        builder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          final onlyYoutube = state.uri.queryParameters['onlyYoutube'] == 'true';
          return ReelsScreen(categoryId: categoryId, onlyYoutube: onlyYoutube);
        },
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/create-reel',
        builder: (context, state) => const CreateReelScreen(),
      ),
      GoRoute(
        path: '/flashcards/create',
        builder: (context, state) => const CreateFlashcardSetScreen(),
      ),
      GoRoute(
        path: '/flashcards/study/:setId',
        builder: (context, state) {
          final setId = state.pathParameters['setId']!;
          return StudyScreen(setId: setId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
