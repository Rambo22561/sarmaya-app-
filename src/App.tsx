/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export default function App() {
  return (
    <main className="min-h-screen bg-[#0B1F3A] text-white flex items-center justify-center p-6">
      <div className="max-w-2xl w-full bg-white text-slate-900 rounded-2xl p-8 shadow-xl space-y-5">
        <div className="inline-block px-3 py-1 rounded-md bg-emerald-100 text-emerald-800 text-xs font-bold tracking-wide uppercase">
          Flutter + Dart + Firebase Codebase Ready for Export
        </div>
        <h1 className="text-2xl font-bold text-[#0B1F3A]">
          Sarmaya Market — Business Investment &amp; Product Ownership Marketplace
        </h1>
        <p className="text-sm text-slate-600 leading-relaxed">
          Per your explicit requirement to build exclusively in{' '}
          <strong>Flutter and Dart</strong> (not React or Next.js), the complete
          production-structured Flutter application, Firebase Cloud Functions,
          Firestore security rules, Storage rules, Android config, and Web config
          have been generated in this workspace root.
        </p>
        <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 text-xs font-mono text-slate-800 space-y-1">
          <div>pubspec.yaml &amp; lib/ (20 User Screens + 9 Admin Screens)</div>
          <div>functions/src/index.ts (Cloud Functions &amp; Double-Entry Ledger)</div>
          <div>firestore.rules, storage.rules, firestore.indexes.json</div>
          <div>android/ &amp; web/ configurations + README.md</div>
        </div>
        <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 text-xs text-amber-900 leading-relaxed">
          <strong>Why this preview is not running Flutter directly:</strong>{' '}
          The AI Studio live preview container only runs Node.js/Vite and does
          not include the Flutter or Dart SDK. Export this project to VS Code or
          Android Studio and run:
          <pre className="mt-2 bg-amber-100/70 p-2 rounded text-[11px]">
            flutter pub get{'\n'}flutterfire configure{'\n'}flutter run -d chrome{'\n'}flutter build apk --release
          </pre>
        </div>
      </div>
    </main>
  );
}
