//
//  MediaSourceModule.swift
//  ErmisStreamNative
//
//  Created by Giáp Phan Văn on 4/10/25.
//

import Foundation
import VideoToolbox
import AVFoundation
import AudioToolbox
struct VideoConfig: Codable{
  var codec : String
  var codedWidth : Int
  var codedHeight : Int
  var frameRate : Int
  var description : String
}

struct AudioConfig: Codable{
  var sampleRate : Int
  var numberOfChannels : Int
  var codec : String
  var description : String
}

struct StreamConfig : Codable{
  var type : String
  var videoConfig : VideoConfig
  var audioConfig : AudioConfig
}


@objcMembers
class CodecSwift: NSObject {
  private static var url : URL?
  private var socketSession : URLSession?
  private var socketTask : URLSessionWebSocketTask?
  private var videoDecoder : VTDecompressionSession?
  
  private var videoFormatDesc: CMFormatDescription?
  private var audioFormatDesc : CMFormatDescription?
  
  private static var videodisplayer : AVSampleBufferDisplayLayer?
  private static var audioplayer : AVSampleBufferAudioRenderer?
  private static var synchro = AVSampleBufferRenderSynchronizer()
  
  private var isPlaying = false
  private var audioTimestamp = CMTime.zero
  override init() {
    self.socketSession = nil
    self.socketTask = nil
    self.videoDecoder = nil
    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setCategory(.playback, mode: .default)
    try? audioSession.setActive(true, options: [])
    super.init()
  }
  
  private func setupPlayer() {
    
  }
  
  static func attachId(Id : String) {
//    self.url = URL(string: "wss://streaming.ermis.network/stream-gate/software/Ermis-streaming/\(Id)")
    self.url = URL(string: "wss://streaming.ermis.network/stream-gate/software/Ermis-streaming/c6bb6751-8595-495a-ae9c-7d21b79ef834")
    
  }
  
  static func attachPlayer(videoplayer : AVSampleBufferDisplayLayer, audioplayers : AVSampleBufferAudioRenderer) {
    self.videodisplayer = videoplayer
    self.audioplayer = audioplayers
    synchro.addRenderer(audioplayer!)
    synchro.addRenderer(videodisplayer!)
  }
  
  func startWebSocket() {
    self.socketSession = URLSession(configuration: .default)
    self.socketTask = socketSession?.webSocketTask(with: CodecSwift.url!)
    CodecSwift.synchro.rate = 1.0
    readMessage()
  }

  func stopWebSocket() {
    socketTask?.cancel(with: .goingAway, reason: nil)
    CodecSwift.videodisplayer?.flush()
    CodecSwift.audioplayer?.flush()
  }
  
  
  private func readMessage() {
    socketTask?.resume();
    socketTask?.receive { result in
      switch result {
        case .failure(let error): print("fail : \(error)")
        case .success(let message):
            switch message {
              case .data(let data):
                guard !data.isEmpty else {
                  return
                }
                self.decodeFrame(data)
              case .string(let config):
                guard !config.isEmpty else {
                  return
                }
                 self.setupConfigFormat(config)
              @unknown default:
                break
            }
        self.readMessage()
      }
    }
  }

  private func decodeFrame(_ data: Data) {
    let uint32value: UInt32 = data.prefix(4).withUnsafeBytes {
        $0.load(as: UInt32.self)
    }
    let timeStamp = CMTime(value: CMTimeValue(UInt32(bigEndian: uint32value)), timescale: 1000);
    let frameType : UInt8 = data[4]
    let framedata = data.subdata(in: 5..<data.count)
    if(frameType != 2) {
      decodeVideoFrame(framedata, timestamp: timeStamp)
    } else if(frameType == 2){
      decodeAudioFrame(framedata, timestamp: timeStamp)
    }
    
  }
  
  private func decodeVideoFrame(_ data: Data, timestamp: CMTime) {
      guard let formatDesc = videoFormatDesc else {
          print("❌ Video format not configured")
          return
      }

      // Create block buffer
      var blockBuffer: CMBlockBuffer?
      var status = CMBlockBufferCreateWithMemoryBlock(
          allocator: kCFAllocatorDefault,
          memoryBlock: nil,
          blockLength: data.count,
          blockAllocator: kCFAllocatorDefault,
          customBlockSource: nil,
          offsetToData: 0,
          dataLength: data.count,
          flags: 0,
          blockBufferOut: &blockBuffer
      )

      guard status == noErr, let blockBuffer = blockBuffer else {
          print("❌ Failed to create video block buffer")
          return
      }

      // Copy data
      status = data.withUnsafeBytes { ptr in
          CMBlockBufferReplaceDataBytes(
              with: ptr.baseAddress!,
              blockBuffer: blockBuffer,
              offsetIntoDestination: 0,
              dataLength: data.count
          )
      }

      guard status == noErr else {
          print("❌ Failed to copy video data")
          return
      }

      // Create sample buffer
      var timing = CMSampleTimingInfo(
          duration: CMTime(value: 1, timescale: 60),
          presentationTimeStamp: timestamp,
          decodeTimeStamp: .invalid
      )

      var sampleBuffer: CMSampleBuffer?
      status = CMSampleBufferCreateReady(
          allocator: kCFAllocatorDefault,
          dataBuffer: blockBuffer,
          formatDescription: formatDesc,
          sampleCount: 1,
          sampleTimingEntryCount: 1,
          sampleTimingArray: &timing,
          sampleSizeEntryCount: 1,
          sampleSizeArray: [data.count],
          sampleBufferOut: &sampleBuffer
      )

      guard status == noErr, let sampleBuffer = sampleBuffer else {
          print("❌ Failed to create video sample buffer")
          return
      }

      // Enqueue to video layer
    if CodecSwift.videodisplayer!.isReadyForMoreMediaData {
      CodecSwift.videodisplayer!.enqueue(sampleBuffer)

//           Start playback if not started
          if !isPlaying {
              CodecSwift.synchro.setRate(1.0, time: timestamp)
              isPlaying = true
              print("▶️ Playback started")
          }
      } else {
          print("⚠️ Video layer not ready")
      }
  }
  
  private func decodeAudioFrame(_ data: Data, timestamp: CMTime) {
      guard let formatDesc = audioFormatDesc else {
          print("❌ Audio format not configured")
          return
      }

      // Strip ADTS header if present
      var audioData = data
      if isADTSHeader(data) {
          let headerSize = (data[1] & 0x01) == 0 ? 9 : 7
          audioData = data.subdata(in: headerSize..<data.count)
      }

      // Create block buffer
      var blockBuffer: CMBlockBuffer?
      var status = CMBlockBufferCreateWithMemoryBlock(
          allocator: kCFAllocatorDefault,
          memoryBlock: nil,
          blockLength: audioData.count,
          blockAllocator: kCFAllocatorDefault,
          customBlockSource: nil,
          offsetToData: 0,
          dataLength: audioData.count,
          flags: 0,
          blockBufferOut: &blockBuffer
      )

      guard status == noErr, let blockBuffer = blockBuffer else {
          print("❌ Failed to create audio block buffer")
          return
      }

      // Copy data
      status = audioData.withUnsafeBytes { ptr in
          CMBlockBufferReplaceDataBytes(
              with: ptr.baseAddress!,
              blockBuffer: blockBuffer,
              offsetIntoDestination: 0,
              dataLength: audioData.count
          )
      }

      guard status == noErr else {
          print("❌ Failed to copy audio data")
          return
      }

      // Calculate continuous timestamp
      let currentTimestamp: CMTime
      if audioTimestamp == .zero {
          currentTimestamp = timestamp
      } else {
          let frameDuration = CMTime(value: 1024, timescale: 48000)
          currentTimestamp = CMTimeAdd(audioTimestamp, frameDuration)
      }
      audioTimestamp = currentTimestamp

      // Create packet description
      var packetDesc = AudioStreamPacketDescription(
          mStartOffset: 0,
          mVariableFramesInPacket: 0,
          mDataByteSize: UInt32(audioData.count)
      )

      // Create sample buffer
      var sampleBuffer: CMSampleBuffer?
      status = CMAudioSampleBufferCreateReadyWithPacketDescriptions(
          allocator: kCFAllocatorDefault,
          dataBuffer: blockBuffer,
          formatDescription: formatDesc,
          sampleCount: 1,
          presentationTimeStamp: currentTimestamp,
          packetDescriptions: &packetDesc,
          sampleBufferOut: &sampleBuffer
      )

      guard status == noErr, let sampleBuffer = sampleBuffer else {
          print("❌ Failed to create audio sample buffer: \(status)")
          return
      }
    enqueueAudio(sampleBuffer)
  }
  
  private func setupConfigFormat(_ config : String) {
    let streamconfig = getStreamConfig(config: config)
    guard streamconfig != nil else {
      return
    }
    let video_description = streamconfig?.videoConfig.description
    let audio_description = streamconfig?.audioConfig.description
    
   
    let accData = Data(base64Encoded: audio_description!)
    let avccData = Data(base64Encoded: video_description!)
    audioFormatDesc = createAudioFormatDescription(accData!, streamconfig?.audioConfig);
    videoFormatDesc = createVideoFormatDescription(avccData!)
  }
  
  private func getStreamConfig(config : String) -> StreamConfig? {
    let data = Data(config.utf8);
    do {
      let configdata = try JSONDecoder().decode(StreamConfig.self, from: data)
      return configdata
    } catch {
      return nil
    }
  }
  
  private func createVideoFormatDescription(_ avcCData: Data) -> CMVideoFormatDescription? {
      let avcCNSData = avcCData as CFData
      
      let extensions: CFDictionary = [
          kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms as String: [
              "avcC": avcCNSData
          ]
      ] as CFDictionary
     
      var formatDesc: CMVideoFormatDescription?
      
      let status = CMVideoFormatDescriptionCreate(
          allocator: kCFAllocatorDefault,
          codecType: kCMVideoCodecType_H264,
          width: 1280,
          height: 720,
          extensions: extensions,
          formatDescriptionOut: &formatDesc
      )

      guard status == noErr else {
        print("error")
        return nil
      }
    
      return formatDesc!
  }
  
  private func createAudioFormatDescription(_ aaCData: Data, _ audio_config : AudioConfig?) -> CMAudioFormatDescription? {
    let sampleRate = Float64(audio_config!.sampleRate)
    var formatDesc: CMAudioFormatDescription?
    var asbd = AudioStreamBasicDescription(
      mSampleRate: sampleRate,
      mFormatID: kAudioFormatMPEG4AAC,
      mFormatFlags: 0,
      mBytesPerPacket: 0,
      mFramesPerPacket: 1024,
      mBytesPerFrame: 0,
      mChannelsPerFrame: UInt32(audio_config?.numberOfChannels ?? 2),
      mBitsPerChannel: 0,
      mReserved: 0)
 
    let status = aaCData.withUnsafeBytes { aaCBytes in
      CMAudioFormatDescriptionCreate(
          allocator: kCFAllocatorDefault,
          asbd: &asbd,
          layoutSize: 0,
          layout: nil,
          magicCookieSize: aaCData.count,
          magicCookie: aaCBytes.baseAddress,
          extensions: nil,
          formatDescriptionOut: &formatDesc
      )
  }
    
      guard status == noErr else {
        print("error")
        return nil
      }
      return formatDesc!
  }
  
  private func isADTSHeader(_ data: Data) -> Bool {
      guard data.count >= 2 else { return false }
      return data[0] == 0xFF && (data[1] & 0xF0) == 0xF0
  }

  
  private func enqueueAudio(_ sb: CMSampleBuffer, retries: Int = 3) {
    
    print(CodecSwift.audioplayer!.isReadyForMoreMediaData)
    if CodecSwift.audioplayer!.isReadyForMoreMediaData {
        CodecSwift.audioplayer!.enqueue(sb)
      let pts = CMSampleBufferGetPresentationTimeStamp(sb)
          switch CodecSwift.audioplayer!.status {
          case .rendering:
              print("[Audio] Enqueued audio at PTS: \(pts). Status: rendering")
          case .failed:
              print("[Audio] Renderer failed: \(CodecSwift.audioplayer!.error?.localizedDescription ?? "Unknown")")
          default:
              print("[Audio] Enqueued audio at PTS: \(pts). Status: \(CodecSwift.audioplayer!.status)")
          }
      
    }  else {
        print("error")
    }
 
    
  }
}

