import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import Login from './components/Login';
import Register from './components/Register';
import ParentDashboard from './components/ParentDashboard';
import ChildDashboard from './components/ChildDashboard';
import { AuthProvider, useAuth } from './context/AuthContext';
import './App.css';

function PrivateRoute({ children, requireRole }) {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="loading-container">
        <div className="spinner"></div>
        <p>Loading...</p>
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" />;
  }

  if (requireRole && user.role !== requireRole) {
    return <Navigate to={user.role === 'parent' ? '/parent' : '/child'} />;
  }

  return children;
}

function AppRoutes() {
  const { user } = useAuth();

  return (
    <Routes>
      <Route path="/login" element={user ? <Navigate to={user.role === 'parent' ? '/parent' : '/child'} /> : <Login />} />
      <Route path="/register" element={user ? <Navigate to={user.role === 'parent' ? '/parent' : '/child'} /> : <Register />} />
      <Route
        path="/parent"
        element={
          <PrivateRoute requireRole="parent">
            <ParentDashboard />
          </PrivateRoute>
        }
      />
      <Route
        path="/child"
        element={
          <PrivateRoute requireRole="child">
            <ChildDashboard />
          </PrivateRoute>
        }
      />
      <Route path="/" element={<Navigate to={user ? (user.role === 'parent' ? '/parent' : '/child') : '/login'} />} />
    </Routes>
  );
}

function App() {
  return (
    <AuthProvider>
      <Router>
        <AppRoutes />
      </Router>
    </AuthProvider>
  );
}

export default App;

