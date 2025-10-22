import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: [['babel-plugin-react-compiler']],
      },
    }),
   
    tailwindcss(),
  ],
  server: {
    host: true, // Cho phép truy cập từ bên ngoài
    allowedHosts: [
      '07901985557d.ngrok-free.app', // Thêm ngrok domain của bạn
      '.ngrok-free.app', // Hoặc cho phép tất cả ngrok domains
      'hiking-based-possession-motivation.trycloudflare.com',
      'recording-debug-across-stock.trycloudflare.com'
      
    ],  
   
  }
  
})
