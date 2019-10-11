//
//  WIZPhotoCollectionEditorController.h
//  Momentum
//
//  Created by a.vorozhishchev on 19/08/2019.
//  Copyright © 2019 WizAlx. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^WIZPhotoCollectionEditorControllerAction)(int index);
typedef void(^WIZPhotoCollectionEditorControllerDragNDrop)(NSInteger fromIndex, NSInteger toIndex);
typedef void(^WIZPhotoCollectionEditorControllerMassivAction)(NSArray <NSNumber*> *indexes);

typedef enum : NSUInteger {
    kEditorPropertyZoom,
    kEditorPropertyDragNDrop
} kEditorProperty;

@interface WIZPhotoCollectionEditorController : UIViewController

-(void)setPhotos:(NSArray <UIImage*> *)photos;
@property (nonatomic) UIColor *cellBackgroundColor;

-(void)selectImage:(int)selectIndex;
-(void)setProperties:(NSArray <NSNumber*>*)properties;

@property (nonatomic) WIZPhotoCollectionEditorControllerAction selectImage;
@property (nonatomic) WIZPhotoCollectionEditorControllerMassivAction deleteImages;

@property (nonatomic) WIZPhotoCollectionEditorControllerDragNDrop dragNDropAction;

@end

NS_ASSUME_NONNULL_END
