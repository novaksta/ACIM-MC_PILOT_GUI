import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts  1.12
import QtQuick.Dialogs 1.3
import QtQml 2.12


import com.st.motorcontrol.qml 1.0
import motorcontrolregister 1.0
import "."





ScrollView {
    id:scrollview
    width: 1300

    property bool isEnableWithoutConnect: false
    /*****MANDATORY PROPERTIES START***************/
    /* Motor Control Registers decription file to load. */
    property string registerFileDescription: "RegListSTMV2_ACIM.json"

    /* Motor Control Scale register Registers */
    //the scale will be apply to every register with corresponding name
    // must add "C" to Access register in json file to be read at connetion
    // if not defined all scales will be set to 1 at init
    property McRegProxy proxy: McRegProxy {
        id: regProxyScale
        name: "SCALES"

        onValuesChanged: {
            console.log("new SCALES = " + regProxyScale.values )
            mcRegBank.setScaleValue("VOLTAGE_SCALE", 1 ,values[0] );
            mcRegBank.setScaleValue("CURRENT_SCALE", 1,values[1] );
            mcRegBank.setScaleValue("FREQUENCY_SCALE", 1,values[2] );
        }
    }
    /*****MANDATORY PROPERTIES END***************/


    Frame {
        id: surface

        /* Motor Control Application parameters */
        property int minimumSpeed: -4000
        property int maximumSpeed: 4000

        property double minimumTorque: -10
        property double maximumTorque: 10

        property int startupSpeed: 1500
        property int nomimalVBus: 24
        property int maximalVBus: 40

        property int maximumPower: 10
        property int maximumTemperature: 100

        property string version : "v1.6"

        property bool openLoopEnable: false




        //font.pixelSize: 12
        RowLayout {
            id: mainGrid
            spacing: 2
            ColumnLayout {
                id: globalControlColumn

                Layout.alignment: Qt.AlignTop | Qt.AlignLeft

                McStatusBox {
                    id:statusgroupBox
                    title: qsTr("Status")
                    enableDocLink: mcMain.detectSdk()
                    Layout.fillWidth: true
                    scope : 1
                }

                GroupBox {
                    id: motorControlGroupBox

                    Layout.fillWidth: true

                    title: qsTr("Control")

                    ColumnLayout {
                        spacing: 2

                        anchors.fill: parent

                        ComboBox {
                            id: controlMode

                            property var mcRegComboBox:mcRegBank.getRegisterByName("CONTROL_MODE" )

                            Layout.fillWidth: true


                            property McRegProxy proxy: McRegProxy {
                                id: regProxyControlMode

                                onValueChanged: {
                                    //console.log("new Mode  regProxy.value = " + regProxy.value )
                                    if (regProxyControlMode.value < reg.possibleDisplayValues.length)
                                    {
                                        let newModeText = reg.possibleDisplayValues[regProxyControlMode.value]
                                        //console.log("new Mode  newModeText = " + newModeText )
                                        let newIndex =  controlMode.model.indexOf(newModeText)
                                        //console.log("new Mode  newIndex = " + newIndex )
                                        if (newIndex >= 0)
                                            controlMode.currentIndex = newIndex
                                    }
                                }
                                name: "CONTROL_MODE"
                            }

                            model:proxy.reg.possibleDisplayValues

                            onCurrentIndexChanged: {
                                //console.log("new text   = " + controlMode.model[currentIndex] )
                                //console.log("real index  = " + mcRegComboBox.possibleDisplayValues.indexOf(controlMode.model[currentIndex]))
                                proxy.value =  mcRegComboBox.possibleDisplayValues.indexOf(controlMode.model[currentIndex])
                            }

                            onCurrentTextChanged: {
                                console.log("onCurrentTextChanged new text   = " + controlMode.model[currentIndex] + "currentText=" + currentText)
                                if (currentText.indexOf("OPEN_LOOP_VOLTAGE") >=0)
                                {
                                    regSpinBoxIdRef.enabled = false
                                    rampTargetSpeedLabel.text =qsTr("Target OL Speed (RPM)")
                                    //buttonStartSpeedRamp.text = qsTr("SET OPEN LOOP REF")
                                    textButtonRampSpeed.text = qsTr("SET OPEN LOOP REF")
                                }
                                else if (currentText.indexOf("OPEN_LOOP_CURRENT") >=0)
                                {
                                    regSpinBoxIdRef.enabled = true
                                    rampTargetSpeedLabel.text =qsTr("Target OL Speed (RPM)")
                                    //buttonStartSpeedRamp.text = qsTr("SET OPEN LOOP REF")
                                    textButtonRampSpeed.text = qsTr("SET OPEN LOOP REF")
                                }
                                else
                                {
                                    regSpinBoxIdRef.enabled = false
                                    rampTargetSpeedLabel.text =qsTr("Target Speed (RPM)")
                                    //buttonStartSpeedRamp.text = qsTr("Execute Speed Ramp")
                                    textButtonRampSpeed.text = qsTr("Execute Speed Ramp")
                                }
                            }


                            Component.onCompleted: {
                                mcRegComboBox.setPolling(true)
                            }
                        }

                        Button {
                            id: startMotorButton

                            text: qsTr("Start")
                            Layout.fillWidth: true
                            Shortcut {
                                sequence: "Ctrl+R"
                                onActivated: startMotorButton.clicked()
                            }
                            onClicked: mcApplication.startMotor( 1 )
                        }

                        Button {
                            id: stopMotorButton

                            text: qsTr("Stop")
                            Layout.fillWidth: true
                            Shortcut {
                                sequence: "Space"
                                onActivated: stopMotorButton.clicked()
                            }
                            onClicked: mcApplication.stopMotor( 1 )
                        }

                        Button {
                            id: stopRampButton

                            text: qsTr("Stop ramp")
                            Layout.fillWidth: true


                            onClicked: mcApplication.stopRamp( 1 )
                        }
                    } // ColumnLayout
                } // motorControlGroupBox

                GroupBox {
                    id: appConfigGroupBox

                    title: qsTr("Configuration")

                    Layout.fillWidth: true

                    ColumnLayout {

                        Button {
                            id: advancedModeButton

                            Layout.fillWidth: true

                            text: qsTr("Advanced Configuration")
                            checkable: true
                            onCheckedChanged: {

                            }
                        }
                    }
                } // appConfigGroupBox

                Label{
                    id: labelversion
                    text: surface.version
                    x:0
                }

            } // globalControlColumn


            Frame {
                id: surface2
                ColumnLayout {
                    id: globalAppColumn
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    TabBar {
                        id: mainTabBar
                        implicitWidth: 250
                        TabButton { id: tab_buttonApplication ; text: qsTr("Application") }
                        /*
                        TabButton { id: tab_buttonRevup ; text: qsTr("Rev-up") }
                        */
                    }
                    StackLayout {
                        currentIndex: mainTabBar.currentIndex
                        Layout.fillWidth: true


                        Frame{
                            RowLayout {
                                id: mainAppTabGrid

                                StackLayout {
                                    property real controlModeIndex : {
                                        if (controlMode.currentText === "SPEED" || controlMode.currentText ===  "OPEN_LOOP_VOLTAGE" || controlMode.currentText === "OPEN_LOOP_CURRENT")
                                        {
                                            return  1
                                        }
                                        else
                                        {
                                            return 0
                                        }
                                    }
                                    id: controlsStackLayout

                                    currentIndex: controlModeIndex
                                    Layout.alignment: Qt.AlignTop

                                    /* Torque Control */
                                    ColumnLayout {
                                        id: torqueControlColumn

                                        GroupBox {
                                            id : torqueControlGroupBox

                                            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                                            title: qsTr("Torque Control")

                                            ColumnLayout {
                                                McRegCircularGauge {
                                                    id: currentTorqueGauge

                                                    regName: "I_Q_MEAS"

                                                    width: 302
                                                    height: width

                                                    from: -10
                                                    to: 10
                                                } // currentTorqueGauge

                                                McRegView {
                                                    id: currentTorqueView

                                                    regName: "I_Q_MEAS"

                                                    label: qsTr("Torque")
                                                    widthHint: "- 88,888"
                                                    decimals: 3

                                                    Layout.alignment: Qt.AlignHCenter
                                                } // currentTorqueView

                                                ToolSeparator { orientation: Qt.Horizontal }

                                                Slider {
                                                    id: torqueRefSlider

                                                    property real torqueRefRegVal: mcRegBank.getRegisterByName( "I_Q_REF" ).value
                                                    property bool loopBreaker: false

                                                    from: -32768
                                                    to: 32767
                                                    stepSize: (to-from)/600
                                                    snapMode: Slider.NoSnap

                                                    wheelEnabled: true

                                                    Layout.fillWidth: true

                                                    background: Rectangle {
                                                        x: torqueRefSlider.leftPadding
                                                        y: torqueRefSlider.topPadding + torqueRefSlider.availableHeight / 2 - height / 2
                                                        //implicitWidth: 200
                                                        implicitHeight: 6
                                                        width: torqueRefSlider.availableWidth
                                                        height: implicitHeight
                                                        radius: 2
                                                        color: "transparent"

                                                        Rectangle {
                                                            x: 0
                                                            y: parent.height / 2 - height / 2

                                                            width: parent.width
                                                            height: 6
                                                            radius: 3
                                                            color: palette.midlight
                                                        }

                                                        Rectangle {
                                                            x: Math.min( torqueRefSlider.visualPosition, 0.5 ) * parent.width
                                                            y: parent.height / 2 - height / 2
                                                            width: Math.abs( 0.5 - torqueRefSlider.visualPosition) * parent.width
                                                            height: 6
                                                            color: enabled ? palette.highlight : palette.mid
                                                            radius: 3
                                                        }
                                                    } // background

                                                    handle: Rectangle {
                                                        x: torqueRefSlider.leftPadding + torqueRefSlider.visualPosition * (torqueRefSlider.availableWidth - width)
                                                        y: torqueRefSlider.topPadding + torqueRefSlider.availableHeight / 2 - height / 2
                                                        implicitWidth: 20
                                                        implicitHeight: 20
                                                        radius: 10
                                                        color: enabled ? (Math.abs( torqueRefSlider.visualPosition - 0.5 ) > 0.45 ? "red" : (Math.abs( torqueRefSlider.visualPosition - 0.5 ) < 0.1 ? "orange" : palette.button) ) : palette.button
                                                        // speedRefSlider.pressed ? "#f0f0f0" : "#f6f6f6"
                                                        border.color: palette.dark //"#bdbebf"
                                                        border.width: 1
                                                    } // handle

                                                    onValueChanged: {
                                                        if ( ! loopBreaker ) {
                                                            console.log("slider value=" + value)
                                                            console.log("mcRegBank.value(CURRENT_SCALE)=" + mcRegBank.scale("CURRENT_SCALE" ))
                                                            console.log("division=" + value / mcRegBank.scale("CURRENT_SCALE" ))
                                                            mcRegBank.getRegisterByName( "TORQUE_RAMP" ).setValue( [ value/mcRegBank.scale("CURRENT_SCALE" ), 0 ] )
                                                        }
                                                        loopBreaker = false
                                                    } // ValueChanged

                                                    onTorqueRefRegValChanged: {
                                                        loopBreaker = true
                                                        value = torqueRefRegVal
                                                        loopBreaker = false
                                                    }

                                                    Component.onCompleted: {
                                                        value =  torqueRefRegVal
                                                        mcRegBank.getRegisterByName("I_Q_REF" ).setPolling( true )
                                                    }
                                                } // torqueRefSlider

                                                McValueView {
                                                    label: qsTr("Torque Reference")
                                                    unit: "A"
                                                    tooltip: "Use this slider to set the torque generated by the motor"
                                                    widthHint: "- 32,768"
                                                    decimals: 3

                                                    value: torqueRefSlider.value

                                                    Layout.alignment: Qt.AlignHCenter
                                                }
                                            } // ColumnLayout
                                        } // torqueControlGroupBox

                                        GroupBox {
                                            id: torqueRampGroupBox
                                            title: qsTr("Torque Ramp")

                                            Layout.column: 1
                                            Layout.row: 1
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignTop

                                            GridLayout {
                                                columns: 3
                                                anchors.centerIn: parent

                                                Label { text: qsTr("Target Torque") }



                                                SpinBox {
                                                    id: rampTargetTorque
                                                    property real rampTorqueRefRegVal: {
                                                        if (mcRegBank.getRegisterByName( "TORQUE_RAMP" ))
                                                        {
                                                            if (mcRegBank.getRegisterByName( "TORQUE_RAMP" ).values.length > 0)
                                                                return mcRegBank.getRegisterByName( "TORQUE_RAMP" ).values[0]
                                                        }
                                                        return 0
                                                    }


                                                    //property real rampTorqueRefRegVal: mcRegBank.getRegisterByName( "I_Q_REF" ).value

                                                    from: surface.minimumTorque * Math.pow(10,decimals)
                                                    to: surface.maximumTorque * Math.pow(10,decimals)
                                                    stepSize: Math.pow(10,decimals)

                                                    //allow float
                                                    property int decimals: 3
                                                    property real realValue: value / 1000


                                                    validator: DoubleValidator {
                                                        bottom: Math.min(rampTargetTorque.from, rampTargetTorque.to)
                                                        top:  Math.max(rampTargetTorque.from, rampTargetTorque.to)
                                                    }

                                                    textFromValue: function(value, locale) {
                                                        return Number(value / 1000).toLocaleString(locale, 'f', rampTargetTorque.decimals)
                                                    }

                                                    valueFromText: function(text, locale) {
                                                        console.log("valueFromText before text=" + text + " spinbox.value=" + rampTargetTorque.value + " spinbox.from=" + rampTargetTorque.from + " spinbox.to=" + rampTargetTorque.to)
                                                        let torqueValue
                                                        if (text > rampTargetTorque.to / Math.pow(10,decimals))
                                                        {
                                                            console.log("valueFromText limit to " + rampTargetTorque.to / Math.pow(10,decimals))
                                                            rampTargetTorque.value = rampTargetTorque.to / Math.pow(10,decimals)
                                                            torqueValue =  rampTargetTorque.to
                                                        }
                                                        else if (text < rampTargetTorque.from / Math.pow(10,decimals))
                                                        {
                                                            console.log("valueFromText limit to " + rampTargetTorque.from / Math.pow(10,decimals))
                                                            rampTargetTorque.value = rampTargetTorque.from / Math.pow(10,decimals)
                                                            torqueValue =  rampTargetTorque.from
                                                        }
                                                        else
                                                        {
                                                            console.log("valueFromText tex= " + text + " is in range")
                                                            torqueValue =  Number.fromLocaleString(locale, text) * Math.pow(10,decimals)
                                                        }
                                                        return torqueValue
                                                    }


                                                    contentItem: TextInput {
                                                        text: rampTargetTorque.textFromValue( rampTargetTorque.value, rampTargetTorque.locale )
                                                        readOnly: ! rampTargetTorque.editable
                                                        selectByMouse: true

                                                        z: 2
                                                        font: rampTargetTorque.font
                                                        horizontalAlignment: Qt.AlignRight

                                                        validator: rampTargetTorque.validator
                                                        inputMethodHints: Qt.ImhFormattedNumbersOnly

                                                        Keys.onPressed: {
                                                            if ((event.key === Qt.Key_Enter) || (event.key === Qt.Key_Return)) {
                                                                mcRegBank.getRegisterByName( "TORQUE_RAMP" ).setValue( [ Number(text)/mcRegBank.scale("CURRENT_SCALE" ), torqueRampDuration.value ] )
                                                            }
                                                        }
                                                    }

                                                    editable: true
                                                    wheelEnabled: true

                                                    onRampTorqueRefRegValChanged: {
                                                        value = rampTorqueRefRegVal
                                                    }
                                                }

                                                Label { text: qsTr("Amp") }

                                                Label { text: qsTr("Duration") }

                                                SpinBox {
                                                    id: torqueRampDuration

                                                    from: 0
                                                    to: 2000000000
                                                    stepSize: 100

                                                    contentItem: TextInput {
                                                        text: torqueRampDuration.value
                                                        readOnly: ! torqueRampDuration.editable
                                                        selectByMouse: true

                                                        font: torqueRampDuration.font
                                                        horizontalAlignment: Qt.AlignRight

                                                        Keys.onPressed: {
                                                            if ((event.key === Qt.Key_Enter) || (event.key === Qt.Key_Return)) {
                                                                //mcRegBank.getRegisterByName( "TORQUE_RAMP" ).setValue( [ rampTargetTorque.realValue /mcRegBank.scale("CURRENT_SCALE" ), Number(text) ] )
                                                            }
                                                        }
                                                    }

                                                    editable: true
                                                    wheelEnabled: true
                                                }

                                                Label { text: "ms" }

                                                Button {
                                                    id : buttonStartTorqueRamp
                                                    text: qsTr("Execute Torque Ramp")

                                                    Layout.columnSpan: 3
                                                    Layout.fillWidth: true

                                                    onClicked:
                                                    {
                                                        console.log("rampTargetTorque.value=" + rampTargetTorque.realValue)
                                                        console.log("mcRegBank.value(CURRENT_SCALE)=" + mcRegBank.scale("CURRENT_SCALE" ))
                                                        console.log("division=" + rampTargetTorque.realValue / mcRegBank.scale("CURRENT_SCALE" ))


                                                        mcRegBank.getRegisterByName( "TORQUE_RAMP" ).setValue( [ rampTargetTorque.realValue /mcRegBank.scale("CURRENT_SCALE" ), torqueRampDuration.value ] )
                                                    }
                                                }
                                            } // GridLayout
                                        } // torqueRampGroupBox



                                        // *******************************************

                                    } // torqueControlColumn

                                    /* Speed Control */
                                    ColumnLayout {
                                        id: speedControlColumn

                                        GroupBox {
                                            id : speedControlGroupBox

                                            title: qsTr("Speed Control")

                                            Layout.alignment: Qt.AlignTop | Qt.AlignLeft

                                            ColumnLayout {
                                                McRegCircularGauge {
                                                    id: currentSpeedGauge

                                                    regName: "SPEED_MEAS"

                                                    width: 302
                                                    height: width

                                                    from: surface.minimumSpeed
                                                    to: surface.maximumSpeed
                                                }

                                                McRegView {
                                                    regName: "SPEED_MEAS"

                                                    label: qsTr("Mechanical Speed")
                                                    widthHint: "- 88888"

                                                    Layout.alignment: Qt.AlignHCenter
                                                }

                                                ToolSeparator { orientation: Qt.Horizontal }

                                                Slider {
                                                    id: speedRefSlider

                                                    property real rampTargetSpeedRegVal: {
                                                        if (mcRegBank.getRegisterByName( "SPEED_RAMP" ))
                                                        {
                                                            if (mcRegBank.getRegisterByName( "SPEED_RAMP" ).values.length > 0)
                                                                return mcRegBank.getRegisterByName( "SPEED_RAMP" ).values[0]
                                                        }
                                                        return 0
                                                    }
                                                    property bool loopBreaker: false

                                                    from: surface.minimumSpeed
                                                    to: surface.maximumSpeed
                                                    stepSize: (to-from)/600
                                                    snapMode: Slider.NoSnap

                                                    wheelEnabled: true

                                                    Layout.fillWidth: true

                                                    background: Rectangle {
                                                        x: speedRefSlider.leftPadding
                                                        y: speedRefSlider.topPadding + speedRefSlider.availableHeight / 2 - height / 2
                                                        //implicitWidth: 200
                                                        implicitHeight: 6
                                                        width: speedRefSlider.availableWidth
                                                        height: implicitHeight
                                                        radius: 2
                                                        color: "transparent"

                                                        Rectangle {
                                                            x: 0
                                                            y: parent.height / 2 - height / 2

                                                            width: parent.width
                                                            height: 6
                                                            radius: 3
                                                            color: palette.midlight
                                                        }

                                                        Rectangle {
                                                            x: Math.min( speedRefSlider.visualPosition, 0.5 ) * parent.width
                                                            y: parent.height / 2 - height / 2
                                                            width: Math.abs( 0.5 - speedRefSlider.visualPosition) * parent.width
                                                            height: 6
                                                            color: enabled ? palette.highlight : palette.mid
                                                            radius: 3
                                                        }
                                                    } // background

                                                    handle: Rectangle {
                                                        x: speedRefSlider.leftPadding + speedRefSlider.visualPosition * (speedRefSlider.availableWidth - width)
                                                        y: speedRefSlider.topPadding + speedRefSlider.availableHeight / 2 - height / 2
                                                        implicitWidth: 20
                                                        implicitHeight: 20
                                                        radius: 10
                                                        color: enabled ? (Math.abs( speedRefSlider.visualPosition - 0.5 ) > 0.45 ? "red" : (Math.abs( speedRefSlider.visualPosition - 0.5 ) < 0.1 ? "orange" : palette.button) ) : palette.button
                                                        // speedRefSlider.pressed ? "#f0f0f0" : "#f6f6f6"
                                                        border.color: palette.dark //"#bdbebf"
                                                        border.width: 1
                                                    }

                                                    onValueChanged: {
                                                        console.log( "speedRefSlider onValueChanged...value=" + value)
                                                        if ( ! loopBreaker ) {
                                                            console.log( "speedRefSlider onValueChanged programming into FW" )
                                                            mcRegBank.getRegisterByName( "SPEED_RAMP" ).setValue( [ value, 0  ] )
                                                            speedRef.value = Math.round(value)
                                                        }

                                                        console.log( "speedRefSlider onValueChanged... done" )
                                                        loopBreaker = false
                                                    }

                                                    onRampTargetSpeedRegValChanged: {
                                                        loopBreaker = true
                                                        console.log( "speedRefSlider onRampTargetSpeedRegValChanged about to set " + rampTargetSpeedRegVal )
                                                        value = rampTargetSpeedRegVal
                                                        console.log( "speedRefSlider onRampTargetSpeedRegValChanged did set " )
                                                        loopBreaker = false
                                                    }

                                                    Component.onCompleted: value = surface.startupSpeed
                                                }

                                                McRegView {
                                                    id : speedRef
                                                    label: qsTr("Speed Reference")
                                                    unit: qsTr("RPM")
                                                    tooltip: qsTr("Use this slider to set the rotation speed of the motor")
                                                    widthHint: {
                                                        console.log ("minimumSpeed = " + surface.minimumSpeed)
                                                        if (surface.minimumSpeed)
                                                            return Number(surface.minimumSpeed).toLocaleString( Qt.locale("C"), 'f', decimals )
                                                    }

                                                    regName: "SPEED_REF"

                                                    onValueChanged: {
                                                        if (!speedRefSlider.pressed)
                                                        {
                                                            //console.log ("speedRefSlider.pressed = false")
                                                            speedRefSlider.loopBreaker = true
                                                            speedRefSlider.value = value
                                                            speedRefSlider.loopBreaker = false
                                                        }
                                                        else
                                                        {
                                                            //console.log ("speedRefSlider.pressed = true -> don't update")
                                                        }
                                                    }


                                                    //value: Math.round(speedRefSlider.value)

                                                    Layout.alignment: Qt.AlignHCenter
                                                    //Component.onCompleted: console.log ( "Speed Reference : " + Number(minimumSpeed).toLocaleString( Qt.locale("C"), 'f', decimals ) )
                                                }
                                            } // ColumnLayout
                                        } // speedControlGroupBox

                                        GroupBox {
                                            id: speedRampGroupBox
                                            title: qsTr("Speed Ramp")

                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignTop

                                            GridLayout {
                                                columns: 3
                                                anchors.centerIn: parent

                                                Label { id : rampTargetSpeedLabel ;text: qsTr("Target Speed") }

                                                SpinBox {
                                                    id: rampTargetSpeed

                                                    // TBD: change
                                                    property real rampTargetSpeedRegVal: {
                                                        if (mcRegBank.getRegisterByName( "SPEED_RAMP" ))
                                                        {
                                                            if (mcRegBank.getRegisterByName( "SPEED_RAMP" ).values.length > 0)
                                                                return mcRegBank.getRegisterByName( "SPEED_RAMP" ).values[0]
                                                        }
                                                        return 0
                                                    }

                                                    from: surface.minimumSpeed
                                                    to: surface.maximumSpeed

                                                    contentItem: TextInput {
                                                        text: rampTargetSpeed.value
                                                        readOnly: ! rampTargetSpeed.editable
                                                        selectByMouse: true

                                                        font: rampTargetSpeed.font
                                                        horizontalAlignment: Qt.AlignRight

                                                        Keys.onPressed: {
                                                            if ((event.key === Qt.Key_Enter) || (event.key === Qt.Key_Return)) {
                                                                mcRegBank.getRegisterByName( "SPEED_RAMP" ).setValue( [ Number(text), speedRampDuration.value  ] )
                                                            }
                                                        }
                                                    }

                                                    editable: true
                                                    wheelEnabled: true

                                                    onRampTargetSpeedRegValChanged: {
                                                        value = rampTargetSpeedRegVal
                                                    }

                                                    Component.onCompleted: value = surface.startupSpeed
                                                }

                                                Label { text: qsTr("RPM") }

                                                Label { text: qsTr("Duration") }

                                                SpinBox {
                                                    id: speedRampDuration

                                                    from: 0
                                                    to: 2000000000
                                                    stepSize: 100

                                                    contentItem: TextInput {
                                                        text: speedRampDuration.value
                                                        readOnly: ! speedRampDuration.editable
                                                        selectByMouse: true

                                                        font: speedRampDuration.font
                                                        horizontalAlignment: Qt.AlignRight

                                                        Keys.onPressed: {
                                                            if ((event.key === Qt.Key_Enter) || (event.key === Qt.Key_Return)) {
                                                                mcRegBank.getRegisterByName( "SPEED_RAMP" ).setValue( [ rampTargetSpeed.value, Number(text) ] )
                                                            }
                                                        }
                                                    }

                                                    editable: true
                                                    wheelEnabled: true
                                                }

                                                Label { text: qsTr("ms") }

                                                Button {
                                                    id : buttonStartSpeedRamp
                                                    //text: qsTr("Execute Speed Ramp")

                                                    Layout.columnSpan: 3
                                                    Layout.fillWidth: true

                                                    Text {
                                                        id: textButtonRampSpeed
                                                        text: qsTr("Execute Speed Ramp")
                                                        anchors.centerIn: parent
                                                        color: 'white'
                                                    }

                                                    onClicked: {
                                                        console.log("Execute Speed Ramp fired!!!")
                                                        mcRegBank.getRegisterByName( "SPEED_RAMP" ).setValue( [ rampTargetSpeed.value, speedRampDuration.value ] )
                                                    }

                                                }
                                            } // GridLayout
                                        } // speedRampGroupBox
                                    } // speedControlColumn

                                } // controlsStackLayout

                                ColumnLayout{
                                    id:measureAndDebugLayout
                                    Layout.alignment: Qt.AlignTop

                                    GroupBox {
                                        id: otherMeasures

                                        title: qsTr("Measures")

                                        Layout.alignment: Qt.AlignTop


                                        ColumnLayout {
                                            spacing: 2

                                            RowLayout{


                                                McRegGaugeVertical{
                                                    id: gaugeVerticalVbus
                                                    regName: "BUS_VOLTAGE"
                                                    label: qsTr("VBUS")
                                                    maximumValue: surface.maximalVBus
                                                    minimumValue: 0
                                                    maxErrorThreshold:  surface.nomimalVBus + (surface.nomimalVBus *50/100)
                                                    maxWarningThreshold:  surface.nomimalVBus + (surface.nomimalVBus *20/100)
                                                    minWarningThreshold:  surface.nomimalVBus - (surface.nomimalVBus *20/100)
                                                    minErrorThreshold:  surface.nomimalVBus - (surface.nomimalVBus *50/100)
                                                }

                                                McRegGaugeVertical{
                                                    id: gaugeVerticalTemp
                                                    regName: "HEATS_TEMP"
                                                    label: qsTr("TEMP")
                                                    maximumValue: surface.maximumTemperature
                                                    maxErrorThreshold:  surface.maximumTemperature*90/100
                                                    maxWarningThreshold:  surface.maximumTemperature*70/100
                                                    tickmarkStepSize: 10
                                                }

                                                McRegGaugeVertical{
                                                    id: gaugeVerticalPower
                                                    regName: "MOTOR_POWER"
                                                    label: qsTr("POWER")
                                                    decimals: 1
                                                    maximumValue: surface.maximumPower
                                                    maxErrorThreshold:  surface.maximumPower*90/100
                                                    maxWarningThreshold:  surface.maximumPower*50/100
                                                }

                                            }


                                            Frame{
                                                Layout.fillWidth: true
//                                                StackLayout {
//                                                    id: sideMeasuresStack

//                                                    Layout.alignment: Qt.AlignHCenter
//                                                    Layout.fillWidth: true

//                                                    currentIndex: 0//controlMode.value

                                                    ColumnLayout {
                                                        id: speedMeasureColumn

                                                        Layout.alignment: Qt.AlignHCenter
                                                        Layout.fillWidth: true


                                                        McRegView {
                                                            regName: "SPEED_MEAS"
                                                            label: qsTr("Speed")
                                                            widthHint: "- 32,768"
                                                            Layout.alignment: Qt.AlignHCenter
                                                            Layout.fillWidth: true
                                                        }

                                                        //ToolSeparator { orientation: Qt.Horizontal }

                                                        McRegView {
                                                            regName: "I_D_MEAS"
                                                            label: qsTr("Id")
                                                            widthHint: "- 32,768"
                                                            Layout.alignment: Qt.AlignHCenter
                                                            Layout.fillWidth: true
                                                            decimals: 2
                                                        }

                                                        McRegView {
                                                            regName: "I_Q_MEAS"
                                                            label: qsTr("Iq")
                                                            widthHint: "- 32,768"
                                                            Layout.alignment: Qt.AlignHCenter
                                                            Layout.fillWidth: true
                                                            decimals: 2
                                                        }
                                                    } // speedMeasureColumn

                                                //}
                                            }

                                        } // other measures column Layout

                                    } // otherMeasures


                                    GroupBox{
                                        id:groupboxSensorSwitch
                                        title: "Switch Sensor"

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        visible: false

                                        ColumnLayout
                                        {
                                            anchors.fill: parent

                                            RowLayout{
                                                Button{
                                                    id: buttonSwitchSensor
                                                    text: "switch"

                                                    onClicked: {
                                                        mcApplication.sensorSwitch( 1 ,switchAngleMargin.value / 0.005493)
                                                    }
                                                }

                                                SpinBox{
                                                    id: switchAngleMargin
                                                    from:0
                                                    to:360
                                                    value: 30
                                                    editable: true




                                                    contentItem: TextInput {
                                                        text: switchAngleMargin.value
                                                        readOnly: ! switchAngleMargin.editable
                                                        selectByMouse: true

                                                        font: switchAngleMargin.font
                                                        horizontalAlignment: Qt.AlignRight
                                                    }

                                                    ToolTip.visible: hovered
                                                    ToolTip.text: qsTr("maximum delta between the main and auxiliary angle sensor to allow switching")

                                                }

                                                Label{
                                                    text: "deg"
                                                }
                                            }
                                        }
                                    }

                                    GroupBox{
                                        id:openLoopParams
                                        title: "OpenLoop"

                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        ColumnLayout
                                        {
                                            anchors.fill: parent

                                            
                                            McRegSpinBoxFloat{ id:regSpinBoxIdRef; regName: "I_D_REF"; label: qsTr("flux Reference"); from: surface.minimumTorque; to: surface.maximumTorque }
                                        }
                                    }
                                } // ColumnLayout

                                ColumnLayout
                                {
                                    Layout.alignment: Qt.AlignTop
                                    McGroupBoxGlobalConfig
                                    {
                                        Layout.alignment: Qt.AlignTop
                                        Layout.fillWidth: true

                                        id:groupBoxGlobalconfig
                                    }

                                    McGroupBoxFWConfig
                                    {
                                        id:groupBoxFWconfig
                                        supportedCtrlType: "FOC"
                                        supportedFOCAlgorithms: ["PLL","CORDIC","HALL","ENCODER"]


                                        //anchors.top: groupBoxGlobalconfig.bottom

                                        onSpeedMaxHasChanged:{surface.maximumSpeed = newMaxSpeed; surface.minimumSpeed = -newMaxSpeed;}
                                        onVbusHasChanged:
                                        {
                                            console.log( "new rated Vbus =  " +  newVbus)
                                            //calculate the closest ten of Vbus
                                            var num_digit = Math.round(newVbus).toString().length;
                                            var unit = Math.round(newVbus).toString()[0]
                                            var vbus_10 = (parseInt(unit,16) + 1) * Math.pow(10,num_digit-1)
                                            if (vbus_10 < 10)
                                                vbus_10 = 10

                                            surface.maximalVBus = vbus_10;
                                            console.log( "vbus_10 =  " +  vbus_10)


                                            surface.nomimalVBus = newVbus;

                                        }
                                        onMaxCurrentHasChanged: {
                                            console.log( " onMaxCurrentHasChanged = " + newMaxReadCurrent)
                                            surface.maximumTorque =     newMaxReadCurrent
                                            surface.minimumTorque =     -newMaxReadCurrent

                                            torqueRefSlider.from = -newMaxReadCurrent
                                            torqueRefSlider.to = newMaxReadCurrent

                                            currentTorqueGauge.from = -newMaxReadCurrent
                                            currentTorqueGauge.to = newMaxReadCurrent

                                        }

                                        onPowerHasChanged:
                                        {
                                            console.log("onPowerHasChanged new power= " + newPower)
                                            surface.maximumPower = newPower;
                                            //gaugeVerticalPower.tickmarkStepSize = newPower / 5;
                                        }
                                        onPrimaySensorHaschanged: {
                                            switch ( primarysensor) {
                                            case 0: /*"No sensor";*/ break;
                                            case 1: groupboxPLL.enabled = true; break;
                                            case 2: groupboxCordic.enabled = true; break;
                                            case 3: /*"Encoder";*/ break;
                                            case 4: /*"Hall sensor"; */break;
                                            case 5: /*"HSO"; */break;
                                            case 6: /*"HSO+ZEST"; */break;
                                            default:break;
                                            }
                                        }

                                        onOpenLoopIsAvailable: {
                                            let modes = Array.from(controlMode.mcRegComboBox.possibleDisplayValues)

                                            console.log( " onOpenLoopIsAvailable = " + openLoopAvailable + " modes = " + modes + " length=" + modes.length)

                                            //Remove unsuppoted state by SDK
                                            let pos = modes.indexOf('OBSERVING')
                                            modes.splice(pos,1)
                                            pos = modes.indexOf('SHORTED')
                                            modes.splice(pos,1)
                                            pos = modes.indexOf('PROFILING')
                                            modes.splice(pos,1)
                                            pos = modes.indexOf('POSITION_CTRL')
                                            modes.splice(pos,1)


                                            if (!openLoopAvailable)
                                            {
                                                pos = modes.indexOf('OPEN_LOOP_VOLTAGE')
                                                modes.splice(pos,1)
                                                pos = modes.indexOf('OPEN_LOOP_CURRENT')
                                                modes.splice(pos,1)
                                            }

                                            controlMode.model = modes
                                            openLoopParams.visible = openLoopAvailable

                                        }
                                    }//McGroupBoxFWConfig
                                }


                            } // RowLayout
                        }
                        /*
                        Frame{
                            Rectangle{
                                anchors.fill: parent
//                                color: "red"

                                RevUpComponent {
                                    id: revupComponent
                                    anchors.fill: parent
                                    maxTorque: surface.maximumTorque
                                }
                            }
                        }
                        */
                    } // StackLayout
                } // ColumnLayout
            }

            GroupBox {
                title: qsTr("Advanced Configuration")
                id : advancedModeGroupBox

                visible: advancedModeButton.checked

                Layout.alignment: Qt.AlignTop

                ColumnLayout {

                    TabBar {
                        id: advancedTabBar

                        TabButton { text: qsTr("Currents & Speed")}
                        TabButton { text: qsTr("Observers") }

                        Layout.fillWidth: true
                    }

                    StackLayout {
                        currentIndex: advancedTabBar.currentIndex

                        Layout.fillWidth: true

                        ColumnLayout {
                            GroupBox {
                                id: piGroupBox

                                title: "Speed PI regulator"

                                ColumnLayout {
                                    McRegGroupSpinBox {
                                        RegDesc { regName: "SPEED_KP"; label: qsTr("Speed Kp" )}
                                        RegDesc { regName: "SPEED_KI"; label: qsTr("Speed Ki") }
                                        //RegDesc { regName: "SPEED_KD" }
                                    }

                                    McRegComboBox {
                                        Layout.fillWidth: true

                                        regName: "SPEED_KP_DIV"
                                        label: qsTr("Kp divisor")
                                    }

                                    McRegComboBox {
                                        Layout.fillWidth: true

                                        regName: "SPEED_KI_DIV"
                                        label: qsTr("Ki divisor")
                                    }
                                }
                            } /* Speed PID */

                            GroupBox {
                                title: qsTr("Torque (Iq) PI regulator")

                                McRegGroupSpinBox {
                                    RegDesc { regName: "I_Q_KP"; label: qsTr("Torque Kp") }
                                    RegDesc { regName: "I_Q_KI"; label: qsTr("Torque Ki") }
                                    //RegDesc { regName: "TORQUE_KD" }
                                }
                            } /* Torque PID */

                            ToolSeparator { orientation: Qt.Horizontal }


                            McRegView { regName: "I_Q_REF"; label: qsTr("Torque Reference") ;decimals: 2}

                            GroupBox {
                                title: qsTr("Flux (Id) PI")

                                McRegGroupSpinBox {
                                    RegDesc { regName: "I_D_KP"; label: qsTr("Flux Kp") }
                                    RegDesc { regName: "I_D_KI"; label: qsTr("Flux Ki") }
                                    //RegDesc { regName: "FLUX_KD" }
                                }
                            } /* Flux PID */

                            ToolSeparator { orientation: Qt.Horizontal }

                            //McRegSpinBox { regName: "I_D_REF"; label: qsTr("Flux Reference   "); from: -32768; to: 32767 }



                        } /* Speed & Current PID Column */


                        ColumnLayout {
                            Layout.fillWidth: true
                            GroupBox {
                                id:groupboxPLL
                                title: qsTr("State Observer with ACIM PLL")
                                enabled:  true
                                height: 200
                                Layout.fillWidth: true
                                ColumnLayout {
                                    Layout.fillWidth: true

                                    McRegSpinBoxFloat {
                                        decimals:2
                                        regName: "ACIM_LSO_K"; 
                                        label: qsTr("K"); 
                                        from: 0.75; 
                                        to: 2.0;
                                    }

                                    McRegSpinBoxFloat {
                                        decimals:0
                                        regName: "ACIM_LSO_KP"; 
                                        label: qsTr("Kp"); 
                                        from: 0.0; 
                                        to: 2000000000.0;
                                        stepSize : 1
                                    }

                                    McRegSpinBoxFloat { 
                                        decimals:0
                                        regName: "ACIM_LSO_KI"; 
                                        label: qsTr("Ki"); 
                                        from: 0.0; 
                                        to: 2000000000.0;
                                        stepSize : 1000
                                    }
                                }
                            } /* Observer + PLL */
                            
                        } /* Observers Column */
                    } // StackLayout
                } // ColumnLayout
            } // Advanced Configuration
        } // RowLayout


    } // Frame

    Component.onCompleted: {

        mcRegBank.getRegisterByName( "FAULTS_FLAGS" ).setPolling( true )
        mcRegBank.getRegisterByName( "STATUS" ).setPolling( true )
        //mcRegBank.getRegisterByName("REVUP_DATA").setPolling(true)
        mcRegBank.enablePolling( true )

        //console.log( "rampDuration font: " + rampDuration.font )


    }


} // ScrollView

