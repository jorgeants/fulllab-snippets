import React from 'react'
import { Text, View, TouchableOpacity, Image, ActivityIndicator } from 'react-native'
import { Camera, Permissions } from 'expo'
import { connect } from 'react-redux'
import { Actions } from 'react-native-router-flux'

import styles from './styles'
import { headerBack, flipCameraIcon, shutterCameraIcon, flashCameraIcon, blankFaceTemplate } from '../../../images/icons'

export default class CameraExample extends React.Component {
  constructor(props) {
    super(props)
    this.state = {
      hasCameraPermission: null,
      type: Camera.Constants.Type.front,
      flashMode: Camera.Constants.FlashMode.off,
      flashModeStyle: styles.flashCameraButtonOff,
      profilePhoto: null,
      loadingPhoto: false,
    }

    this._flipCamera = this._flipCamera.bind(this)
    this._interuptFlash = this._interuptFlash.bind(this)
    this._takePhoto = this._takePhoto.bind(this)
  }

  async componentDidMount() {
    const { status } = await Permissions.askAsync(Permissions.CAMERA)
    this.setState({ hasCameraPermission: status === 'granted' })
  }

  _flipCamera() {
    const { type } = this.state
    const cameraType = Camera.Constants.Type

    this.setState({
      type: type === cameraType.back ? cameraType.front : cameraType.back
    })
  }

  _interuptFlash() {
    const { flashMode } = this.state
    const cameraFlashMode = Camera.Constants.FlashMode

    this.setState({
      flashMode: flashMode === cameraFlashMode.on ? cameraFlashMode.off : cameraFlashMode.on,
      flashModeStyle: flashMode === cameraFlashMode.on ? styles.flashCameraButtonOff : styles.flashCameraButtonOn,
    })
  }

  _takePhoto = async () => {
    if (this.camera) {
      this.setState({
        loadingPhoto: true
      })

      let photo = await this.camera.takePictureAsync({
        base64: true
      })

      Actions.profileEdit({ profilePhoto: photo.base64 })
    }
  };

  render() {
    const { hasCameraPermission, type, flashModeStyle, loadingPhoto } = this.state

    const toogleImageShutterCamera = loadingPhoto ? <ActivityIndicator style={styles.iconShutterCameraButton} /> : <Image source={shutterCameraIcon} resizeMode={'contain'} style={styles.iconShutterCameraButton} />

    if (hasCameraPermission === null) {
      return <View />
    } else if (hasCameraPermission === false) {
      return <Text>Sem permissão para acessar a câmera.</Text>
    } else {
      return (
        <View style={styles.containerView}>
          <Camera style={styles.cameraView} type={type} ref={ref => { this.camera = ref }}>

            <View style={styles.containerHeaderButtons}>
              <View style={styles.buttonsContent}>
                <TouchableOpacity style={{ ...styles.auxiliaryButton, ...styles.headerBackButton}} onPress={() => Actions.pop()}>
                  <Image source={headerBack} resizeMode={'contain'} style={styles.iconBackButton} />
                </TouchableOpacity>
              </View>
            </View>

            <View style={styles.containerMask}>
              <View style={styles.contentMask}>
                <Image source={blankFaceTemplate} resizeMode={'contain'} style={styles.blankFaceTemplateStyle} />
              </View>
            </View>

            <View style={styles.containerButtons}>
              <View style={styles.buttonsContent}>
                <TouchableOpacity style={{ ...styles.auxiliaryButton, ...styles.flipCameraButton }} onPress={this._flipCamera}>
                  <Image source={flipCameraIcon} resizeMode={'contain'} style={styles.iconFlipCameraButton} />
                </TouchableOpacity>
              </View>

              <View style={styles.buttonsContent}>
                <TouchableOpacity style={styles.shutterCameraButton} onPress={this._takePhoto} disabled={loadingPhoto}>
                 { toogleImageShutterCamera }
                </TouchableOpacity>
              </View>

              <View style={styles.buttonsContent}>
                <TouchableOpacity style={{ ...styles.auxiliaryButton, ...flashModeStyle }} onPress={this._interuptFlash}>
                  <Image source={flashCameraIcon} resizeMode={'contain'} style={styles.iconFlashCameraButton} />
                </TouchableOpacity>
              </View>
            </View>

          </Camera>
        </View>
      )
    }
  }
}
