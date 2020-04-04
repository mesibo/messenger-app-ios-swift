//
//  UIView+Visibility.m
//  UIView+Visibility
//
//  Created by neevek on 8/8/17.
//  Copyright (c) 2015 neevek. All rights reserved.
//

#import "UIView+Visibility.h"
#import "NSLayoutConstraint+Visibiltiy.h"

@implementation UIView(Visibility)

-(void)setVisibility:(UIViewVisibility)visibility {
    [self setVisibility:visibility affectedMarginDirections:UIViewMarginDirectionNone];
}

-(void)setVisibility:(UIViewVisibility)visibility affectedMarginDirections:(UIViewMarginDirection)affectedMarginDirections {
    switch (visibility) {
        case UIViewVisibilityVisible:
            self.hidden = NO;
            [[self findConstraintFromView:self forLayoutAttribute:NSLayoutAttributeWidth] restore];
            [[self findConstraintFromView:self forLayoutAttribute:NSLayoutAttributeHeight] restore];
            [self restoreMarginForDirections:affectedMarginDirections];
            break;
        case UIViewVisibilityInvisible:
            self.hidden = YES;
            break;
        case UIViewVisibilityGone:
            self.hidden = YES;
            [[self findConstraintFromView:self forLayoutAttribute:NSLayoutAttributeWidth] clear];
            [[self findConstraintFromView:self forLayoutAttribute:NSLayoutAttributeHeight] clear];
            [self clearMarginForDirections:affectedMarginDirections];
            break;
        default:
            break;
    }
    
    if (visibility != UIViewVisibilityInvisible) {
        [self layoutIfNeeded];
    }
}

-(void)clearMarginForDirections:(UIViewMarginDirection)affectedMarginDirections {
    if (affectedMarginDirections == UIViewMarginDirectionNone) {
        return;
    }
    
    if (UIViewMarginDirectionTop & affectedMarginDirections) {
        [[self findConstraintFromView:self.superview forLayoutAttribute:NSLayoutAttributeTop] clear];
    }
    if (UIViewMarginDirectionLeft & affectedMarginDirections) {
        [[self findConstraintFromView:self.superview forLayoutAttribute:NSLayoutAttributeLeading] clear];
    }
    if (UIViewMarginDirectionBottom & affectedMarginDirections) {
        [[self findConstraintFromView:self.superview forLayoutAttribute:NSLayoutAttributeBottom] clear];
    }
    if (UIViewMarginDirectionRight & affectedMarginDirections) {
        [[self findConstraintFromView:self.superview forLayoutAttribute:NSLayoutAttributeTrailing] clear];
    }
}

-(void)restoreMarginForDirections:(UIViewMarginDirection)affectedMarginDirections {
    if (affectedMarginDirections == UIViewMarginDirectionNone) {
        return;
    }
    
    if (UIViewMarginDirectionTop & affectedMarginDirections) {
        [[self findConstraintFromView:self.superview forLayoutAttribute:NSLayoutAttributeTop] restore];
    }
    if (UIViewMarginDirectionLeft & affectedMarginDirections) {
        [[self findConstraintFromView:self.superview forLayoutAttribute:NSLayoutAttributeLeading] restore];
    }
    if (UIViewMarginDirectionBottom & affectedMarginDirections) {
        [[self findConstraintFromView:self.superview forLayoutAttribute:NSLayoutAttributeBottom] restore];
    }
    if (UIViewMarginDirectionRight & affectedMarginDirections) {
        [[self findConstraintFromView:self.superview forLayoutAttribute:NSLayoutAttributeTrailing] restore];
    }
}

-(NSLayoutConstraint *)findConstraintFromView:(UIView *)view forLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
    for (NSLayoutConstraint *constraint in view.constraints) {
        if ((constraint.firstItem == self && constraint.firstAttribute == layoutAttribute) ||
            (constraint.secondItem == self && constraint.secondAttribute == layoutAttribute)) {
            return constraint;
        }
    }
    
    return nil;
}

@end
