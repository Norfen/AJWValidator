//
//  UITextInput+AJWValidator.m
//  AJWValidator
//
//  Created by Michael Gaylord on 2014/08/28.
//  Copyright (c) 2014 Adam Waite. All rights reserved.
//

#import "UIView+AJWValidator.h"
#import "AJWValidator.h"
#import <objc/runtime.h>

static char AJWValidators;

typedef NS_ENUM(NSUInteger, AJWValidatorInputType) {
    AJWValidatorInputTypeUnsupported,
    AJWValidatorInputTypeUITextField,
    AJWValidatorInputTypeUITextView
};

@implementation UIView (AJWValidator)

#pragma mark Associated Object Accessors

- (NSMutableArray *)AJW_validators {
    return objc_getAssociatedObject(self, &AJWValidators);
}

#pragma mark Supported Input Views

- (AJWValidatorInputType)AJW_validatorType {
    if ([self isKindOfClass:[UITextField class]]) {
        return AJWValidatorInputTypeUITextField;
    }

    if ([self isKindOfClass:[UITextView class]]) {
        return AJWValidatorInputTypeUITextView;
    }

    return AJWValidatorInputTypeUnsupported;
}

#pragma mark Validity

- (BOOL)isValid {
    BOOL b = YES;
    for (AJWValidator *v in [self AJW_validators]) {
        [v validate:[((id)self)text]];
        b &= [v isValid];
    }
    return b;
}

- (NSArray *)validationErrors {
    NSMutableArray *verrors = [[NSMutableArray alloc] init];
    [[self AJW_validators] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [verrors addObjectsFromArray:[obj errorMessages]];
    }];
    return verrors;
}

#pragma mark Attach/Remove

- (void)ajw_attachValidator:(AJWValidator *)validator {
    NSParameterAssert(validator);

    switch ([self AJW_validatorType]) {
        case AJWValidatorInputTypeUITextField:
            [self AJW_attachTextFieldValidator];
            break;
        case AJWValidatorInputTypeUITextView:
            [self AJW_attachTextViewValidator];
            break;
        case AJWValidatorInputTypeUnsupported:
            NSLog(@"Tried to add AJWValidator to unsupported control type of class %@. " @"%s.", [self class], __PRETTY_FUNCTION__);
            NSAssert(NO, nil);
    }

    if (![self AJW_validators]) {
        objc_setAssociatedObject(self, &AJWValidators, [NSMutableArray array], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    [[self AJW_validators] addObject:validator];
}

- (void)ajw_removeValidators {
    [[self AJW_validators] removeAllObjects];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark UITextField

- (void)AJW_attachTextFieldValidator {
    [(UITextField *)self addTarget:self action:@selector(AJW_validateTextFieldForChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)AJW_validateTextFieldForChange:(UITextField *)textField {
    [[self AJW_validators] enumerateObjectsUsingBlock:^(AJWValidator *validator, NSUInteger idx, BOOL *stop) {
      [validator validate:textField.text];
    }];
}

#pragma mark UITextView

- (void)AJW_attachTextViewValidator {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(AJW_validateTextViewForChange:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self];
}

- (void)AJW_validateTextViewForChange:(NSNotification *)notification {
    [[self AJW_validators] enumerateObjectsUsingBlock:^(AJWValidator *validator, NSUInteger idx, BOOL *stop) {
      UITextView *textView = notification.object;
      [validator validate:textView.text];
    }];
}

@end
