import React, { useCallback, useEffect } from 'react';
import {
  Dimensions,
  StyleSheet,
  View,
  TouchableOpacity,
  Modal,
  StatusBar,
} from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  runOnJS,
  interpolate,
  Extrapolation,
  useAnimatedScrollHandler,
  scrollTo,
  useAnimatedRef,
} from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

const { height: SCREEN_HEIGHT } = Dimensions.get('window');

export interface BottomSheetScrollProps {
  scrollRef: ReturnType<typeof useAnimatedRef<Animated.FlatList<any>>>;
  scrollHandler: ReturnType<typeof useAnimatedScrollHandler>;
}

interface BottomSheetProps {
  visible: boolean;
  onClose: () => void;
  children: (scrollProps: BottomSheetScrollProps) => React.ReactNode;
  snapPoints?: [number, number]; // [min, max] as fractions of screen height
}

export const BottomSheet: React.FC<BottomSheetProps> = ({
  visible,
  onClose,
  children,
  snapPoints = [0.5, 1],
}) => {
  const insets = useSafeAreaInsets();

  // Calculate snap positions from fractions
  const MIN_TRANSLATE_Y = -SCREEN_HEIGHT * snapPoints[0];
  const MAX_TRANSLATE_Y = -SCREEN_HEIGHT + 50; // Leave 50px from top

  const translateY = useSharedValue(0);
  const context = useSharedValue({ y: 0, startY: 0 });
  const scrollOffset = useSharedValue(0);
  const isScrolling = useSharedValue(false);
  const isSheetMoving = useSharedValue(false);
  const listRef = useAnimatedRef<Animated.FlatList<any>>();

  const snapTo = useCallback(
    (destination: number) => {
      'worklet';
      translateY.value = withSpring(destination, {
        damping: 50,
        stiffness: 300,
      });
    },
    [translateY]
  );

  const handleClose = useCallback(() => {
    snapTo(0);
    setTimeout(() => {
      onClose();
    }, 300);
  }, [onClose, snapTo]);

  useEffect(() => {
    if (visible) {
      snapTo(MIN_TRANSLATE_Y);
    } else {
      translateY.value = 0;
    }
  }, [visible, snapTo, translateY, MIN_TRANSLATE_Y]);

  // Scroll handler to track scroll position
  const scrollHandler = useAnimatedScrollHandler({
    onScroll: (event) => {
      scrollOffset.value = event.contentOffset.y;
    },
    onBeginDrag: () => {
      isScrolling.value = true;
    },
    onEndDrag: () => {
      isScrolling.value = false;
    },
  });

  // Pan gesture for the sheet
  const panGesture = Gesture.Pan()
    .onStart(() => {
      context.value = { y: translateY.value, startY: 0 };
      isSheetMoving.value = false;
    })
    .onUpdate((event) => {
      const isAtTop = scrollOffset.value <= 0;
      const isDraggingDown = event.translationY > 0;
      const isFullyExpanded = translateY.value <= MAX_TRANSLATE_Y + 1;
      const isNotFullyExpanded = !isFullyExpanded;

      const shouldMoveSheet =
        (isAtTop && isDraggingDown) || isNotFullyExpanded;

      if (shouldMoveSheet) {
        if (!isSheetMoving.value) {
          isSheetMoving.value = true;
          context.value = {
            y: translateY.value,
            startY: event.translationY,
          };
        }

        const delta = event.translationY - context.value.startY;
        const newTranslateY = delta + context.value.y;
        translateY.value = Math.max(newTranslateY, MAX_TRANSLATE_Y);

        if (isNotFullyExpanded && scrollOffset.value > 0) {
          scrollTo(listRef, 0, 0, false);
        }

        if (isAtTop && isDraggingDown && scrollOffset.value < 0) {
          scrollTo(listRef, 0, 0, false);
        }
      } else {
        isSheetMoving.value = false;
      }
    })
    .onEnd((event) => {
      const isAtTop = scrollOffset.value <= 0;

      if (isAtTop || translateY.value > MAX_TRANSLATE_Y + 10) {
        const velocity = event.velocityY;

        if (velocity > 500) {
          if (translateY.value > MIN_TRANSLATE_Y / 2) {
            runOnJS(handleClose)();
            isSheetMoving.value = false;
            return;
          }
          snapTo(MIN_TRANSLATE_Y);
        } else if (velocity < -500) {
          snapTo(MAX_TRANSLATE_Y);
        } else {
          const distToMax = Math.abs(translateY.value - MAX_TRANSLATE_Y);
          const distToMin = Math.abs(translateY.value - MIN_TRANSLATE_Y);
          const distToClose = Math.abs(translateY.value);

          if (distToClose < distToMin && distToClose < distToMax) {
            runOnJS(handleClose)();
          } else if (distToMin < distToMax) {
            snapTo(MIN_TRANSLATE_Y);
          } else {
            snapTo(MAX_TRANSLATE_Y);
          }
        }
      }
      isSheetMoving.value = false;
    });

  const nativeGesture = Gesture.Native();
  const composedGesture = Gesture.Simultaneous(panGesture, nativeGesture);

  const rBottomSheetStyle = useAnimatedStyle(() => {
    const borderRadius = interpolate(
      translateY.value,
      [MAX_TRANSLATE_Y, MIN_TRANSLATE_Y],
      [0, 24],
      Extrapolation.CLAMP
    );

    return {
      borderTopLeftRadius: borderRadius,
      borderTopRightRadius: borderRadius,
      transform: [{ translateY: translateY.value }],
    };
  });

  const rBackdropStyle = useAnimatedStyle(() => {
    const opacity = interpolate(
      translateY.value,
      [0, MIN_TRANSLATE_Y],
      [0, 0.5],
      Extrapolation.CLAMP
    );

    return { opacity };
  });

  if (!visible) return null;

  return (
    <Modal transparent visible={visible} animationType="none">
      <StatusBar barStyle="light-content" />

      {/* Backdrop */}
      <Animated.View
        style={[styles.backdrop, rBackdropStyle]}
        pointerEvents="auto"
      >
        <TouchableOpacity
          style={StyleSheet.absoluteFill}
          onPress={handleClose}
          activeOpacity={1}
        />
      </Animated.View>

      {/* Bottom Sheet */}
      <GestureDetector gesture={composedGesture}>
        <Animated.View
          style={[
            styles.bottomSheet,
            rBottomSheetStyle,
            { paddingBottom: insets.bottom },
          ]}
        >
          {/* Handle */}
          <View style={styles.handleContainer}>
            <View style={styles.handle} />
          </View>

          {children({ scrollRef: listRef, scrollHandler })}
        </Animated.View>
      </GestureDetector>
    </Modal>
  );
};

const styles = StyleSheet.create({
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'black',
  },
  bottomSheet: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: SCREEN_HEIGHT,
    height: SCREEN_HEIGHT,
    backgroundColor: '#1c1c1e',
  },
  handleContainer: {
    alignItems: 'center',
    paddingVertical: 12,
  },
  handle: {
    width: 36,
    height: 5,
    backgroundColor: '#5c5c5e',
    borderRadius: 2.5,
  },
});