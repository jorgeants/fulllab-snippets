import theme from '../../themes/yellow'
import { Dimensions } from 'react-native'

const deviceWindowSize = Dimensions.get('window')

export default {
  containerView: {
    flex: 1,
  },
  cameraView: {
    flex: 1,
    flexDirection: 'column',
  },
  containerHeaderButtons: {
    flex: 0.15,
    flexDirection: 'row',
    alignItems: 'flex-end',
  },
  headerBackButton: {
    marginLeft: 10,
    marginBottom: 10,
  },
  iconBackButton: {
    width: 25,
    height: 25,
    resizeMode: 'contain',
  },
  containerMask: {
    flex: 0.65,
  },
  contentMask: {
    flex: 1,
  },
  contentMask: {
    flex: 1,
    alignSelf: 'center',
    padding: 50,
  },
  blankFaceTemplateStyle: {
    flex: 1,
    alignSelf: 'stretch',
    width: deviceWindowSize.width,
    height: deviceWindowSize.height,
  },
  containerButtons: {
    flex: 0.2,
    flexDirection: 'row',
    justifyContent: 'space-evenly',
    alignItems: 'center',
  },
  buttonsContent: {
    flex: 0.3,
    alignItems: 'center',
  },
  shutterCameraButton: {
    paddingTop: 20,
    paddingRight: 20,
    paddingBottom: 20,
    paddingLeft: 20,
    borderRadius: 60,
    backgroundColor: 'rgba(255, 255, 255, 1)',
  },
  iconShutterCameraButton: {
    width: 42,
    height: 42,
  },
  auxiliaryButton: {
    paddingTop: 12,
    paddingRight: 12,
    paddingBottom: 12,
    paddingLeft: 12,
    borderRadius: 60,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
  },
  iconFlipCameraButton: {
    width: 28,
    height: 28,
  },
  flashCameraButtonOff: {
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
  },
  flashCameraButtonOn: {
    backgroundColor: 'rgba(255, 185, 0, 0.9)',
  },
  iconFlashCameraButton: {
    width: 28,
    height: 28,
  },
}
