import React from 'react';

function App() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-900 via-blue-700 to-blue-400 flex items-center justify-center p-4">
      
      {/* Container principal com efeito Glassmorphism */}
      <div className="bg-white/10 backdrop-blur-lg rounded-3xl p-10 md:p-16 shadow-2xl border border-white/20 text-center max-w-2xl w-full transform transition-all hover:scale-105 duration-500">
        
        <div className="mb-10">
          <h1 className="text-6xl md:text-8xl font-extrabold text-white tracking-tighter mb-4 drop-shadow-lg">
            ☁️ Azure
          </h1>
          <h2 className="text-3xl md:text-5xl font-bold text-blue-200 mb-6 drop-shadow-md">
            Azure Groups Brasil
          </h2>
        </div>

        <div className="inline-block bg-blue-800/40 px-8 py-4 rounded-full border border-blue-300/30 shadow-inner">
          <p className="text-xl md:text-2xl text-blue-50 font-semibold tracking-wide">
            🚀 Azure Container App - github/matias-defrederike
          </p>
        </div>

      </div>
      
    </div>
  );
}

export default App;