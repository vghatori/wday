// GreetingCard.js
import { useState } from 'react';
import { Input, Upload, Button, Typography, List, Avatar } from 'antd';
import { UploadOutlined } from '@ant-design/icons';
import './App.css'
import { useNavigate } from 'react-router-dom';
const { Title } = Typography;
import { message } from 'antd';

const data = [
  {
    title: 'Điền tên người đẹp đi nhoá',
  },
  {
    title: 'Cả ảnh người đẹp nữa nà',
  },
  {
    title: 'Rùi xác nhận nhận qùa ❤️',
  },
];

const GreetingCard = () => {
  const [api, contextHolder] = message.useMessage();
  const [name, setName] = useState('');
  const [imageUrl, setImageUrl] = useState<string>('');
  const navigate = useNavigate()
  
  const handleUpload = (e : any) => {
    const url = URL.createObjectURL(e.fileList[0].originFileObj);
      setImageUrl(url);
      api.success("cảm ơn người đẹp đã upload ảnh của mình ❤️")
  };

  const submit = () => {
    if(name === '') {   
      api.error("tên của người đẹp, em muốn biết 🥺✨")     
    }else if(imageUrl === '') {   
      api.error("em xin ảnh đẹp của người đẹp được không 🥺✨")     
    } else {
      navigate("/greeting", {
          state : {
            name : name,
            imageUrl : imageUrl
          }
      })   
    }
      
  }

  return (
    <div className="App flex flex-col justify-center items-center" >
      {contextHolder}
    <List
    itemLayout="horizontal"
    dataSource={data}
    className ="w-3/6"
    renderItem={(item, index) => (
      <List.Item>
        <List.Item.Meta
          avatar={<Avatar src={`https://api.dicebear.com/7.x/miniavs/svg?seed=${index}`} />}
          title={<p>{item.title}</p>}
          
        />
      </List.Item>
    )}
  />
      <Title style={{ color: '#d63384' }}>🎀 Hello Cô Gái</Title>
    <div className="flex">
      <Input
        placeholder="Nhập tên đi người đẹp ..."
        value={name}
        onChange={(e) => setName(e.target.value)}
        style={{ maxWidth: 400, marginBottom: 16 }}
        required
      />
    
      <Upload
        showUploadList={false}
        beforeUpload={() => false}
        onChange={handleUpload}
      >
        <Button icon={<UploadOutlined />}>Tải ảnh lên</Button>
      </Upload>
    </div>
      
      <Button className ="w-50" onClick={submit}>Nhận Quà</Button>

    </div>
  );
};

export default GreetingCard;
