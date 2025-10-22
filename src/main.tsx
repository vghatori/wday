import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.tsx'
import './App.css'


import GreetingCard from './GreetingCard.js'
import { BrowserRouter, Route, Routes } from 'react-router-dom'


createRoot(document.getElementById('root')!).render(
  <StrictMode>

    <BrowserRouter>  
    <Routes>
      <Route path="/" element={<GreetingCard /> } />
      <Route path="/greeting" element={<App />} />
    </Routes>
    </BrowserRouter>
  </StrictMode>,
)
