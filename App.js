// App.js
import React, { useEffect } from "react";
import { Routes, Route, useNavigate, useLocation } from "react-router-dom";
import RoleBasedDashboard from "./pages/RoleBasedDashboard";
import Settings from "./pages/Settings";
import Alertes from "./pages/Alertes";
import Batches from "./pages/Batches";
import Stocks from "./pages/Stocks";
import Transactions from "./pages/Transactions";
import ProducerDashboard from "./pages/ProducerDashboard";
import ResellerDashboard from "./pages/ResellerDashboard";
import AuthorityDashboard from "./pages/AuthorityDashboard";
import { AppProvider } from "./context/AppContext";
import LandingPage from "./pages/LandingPage";
import Navbar from "./components/Navbar";
import { AdminProvider } from './context/AdminContext';
import UserInspectionPage from './pages/UserInspectionPage'
import { User } from "lucide-react";

// Inactivity timer component
const InactivityTimer = ({ children }) => {
  const navigate = useNavigate();
  const INACTIVE_TIMEOUT = 300000; // 5 minutes in milliseconds
  let timer;

  const resetTimer = () => {
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => {
      navigate('/');
    }, INACTIVE_TIMEOUT);
  };

  useEffect(() => {
    // Setup event listeners
    const events = ['mousedown', 'mousemove', 'keydown', 'scroll', 'touchstart'];
    
    events.forEach(event => {
      document.addEventListener(event, resetTimer);
    });

    // Initial timer
    resetTimer();

    // Cleanup
    return () => {
      if (timer) clearTimeout(timer);
      events.forEach(event => {
        document.removeEventListener(event, resetTimer);
      });
    };
  }, []);

  return children;
};

function App() {
  const location = useLocation(); // Get the current route

  return (
    <AppProvider>
      <AdminProvider>
        <InactivityTimer>
          <div className="flex flex-col min-h-screen bg-gray-100">
            {/* Render Navbar */}
            {location.pathname !== "/" && <Navbar />}
            <div className={`flex-1 transition-all duration-300 ease-in-out`}>
              <Routes>
                <Route path="/" element={<LandingPage />} />
                <Route path="/dashboard" element={<RoleBasedDashboard />} />
                <Route path="/settings" element={<Settings />} />
                <Route path="/alerts" element={<Alertes />} />
                <Route path="/batches" element={<Batches />} />
                <Route path="/stocks" element={<Stocks />} />
                <Route path="/transactions" element={<Transactions />} />
                <Route path="/producer" element={<ProducerDashboard />} />
                <Route path="/reseller" element={<ResellerDashboard />} />
                <Route path="/authority" element={<AuthorityDashboard />} />
                <Route path="/inspection" element={<UserInspectionPage/>}/>
              </Routes>
            </div>
          </div>
        </InactivityTimer>
      </AdminProvider>
    </AppProvider>
  );
}

export default App;