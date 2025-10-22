import { useEffect, useState } from 'react';
import {Image, message} from "antd" 
import { useLocation, useNavigate } from 'react-router-dom';

import { FaRegFaceKissWinkHeart } from "react-icons/fa6";
import { FaHandPointLeft } from "react-icons/fa6";
import { FaHandPointRight } from "react-icons/fa6";



const wishes = [
  "Chúc cô gái luôn xinh đẹp, mạnh khỏe và hạnh phúc!",
  "Chúc một nửa thế giới luôn rạng rỡ như hoa!",
  "Chúc cô gái luôn thành công trong công việc và cuộc sống!",
  "20/10 vui vẻ! Mong cô gái luôn được yêu thương và trân trọng!",
  "Chúc bạn ngày 20/10 tràn ngập niềm vui và nụ cười!" 
];

function App() {
  const [api, contextHolder] = message.useMessage();
  const [wish, setWish] = useState(wishes[0]);
  const[index, setIndex] = useState(0)
  const location = useLocation();
  const { state } = location
  const navigate = useNavigate()
  useEffect(() => {
    api.success("thankiuuuu!!")
  },[])
  const randomWish = () => {
    if(index == 4) {
      api.success("cảm ơn vì đã dành ít thời gian để xem hết thư chúc này")
      setTimeout(() => {
        navigate("/")
      }, 2000)
    }

    setIndex(index + 1)
    setWish(wishes[index]);
  };
  return (
    <div className="App flex flex-col items-center justify-center">
      {contextHolder}
      <h1>🌸 Chúc mừng Ngày Phụ nữ Việt Nam 20/10 nhé {state.name} 🌸</h1>
      <div className = "flex gap-2 mb-2">
        <FaHandPointRight />
        <FaHandPointLeft />
      </div>
      <div className="shiny-wrapper" >
      <Image
        src={state.imageUrl}
        preview={true}
        width={"20%"}
        className="shiny-image"
      />
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="sparkle"></div>
      <div className="shine-effect" />
    </div>
      

      <p className="wish flex gap-2.5">{wish} <FaRegFaceKissWinkHeart /></p>
      <button onClick={randomWish} className='w-50'>🌼 Click đi hẹ hẹ</button>
      
    </div>
  );
}

export default App;
