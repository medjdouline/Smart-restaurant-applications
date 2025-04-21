from rest_framework import permissions
from core.firebase_crud import firebase_crud

class IsClient(permissions.BasePermission):
    """Allows access only to authenticated non-guest clients"""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
            
        # Check claims first
        if hasattr(request.user, 'claims'):
            return (
                request.user.claims.get('role') == 'client' and 
                not request.user.claims.get('is_guest', False)
            )
            
        # Fallback to Firestore check
        client = firebase_crud.get_doc('clients', request.user.uid)
        return client and not client.get('isGuest', False)

class IsGuest(permissions.BasePermission):
    """Allows access only to guest users"""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
            
        # Check claims first
        if hasattr(request.user, 'claims'):
            return request.user.claims.get('is_guest', False)
            
        # Fallback to Firestore check
        client = firebase_crud.get_doc('clients', request.user.uid)
        return client and client.get('isGuest', True)

class IsTableClient(permissions.BasePermission):
    """Allows access to any authenticated user at a table (client or guest)"""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # All authenticated users at the table, whether guests or regular clients
        return True

class IsStaff(permissions.BasePermission):
    """Allows access to any staff member (server, chef, or manager)"""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
            
        # Check claims first
        if hasattr(request.user, 'claims'):
            return request.user.claims.get('role') in ['server', 'chef', 'manager']
            
        # Fallback to Firestore check
        employes = firebase_crud.query_collection(
            'employes',
            'firebase_uid',
            '==',
            request.user.uid
        )
        return bool(employes)

class IsServer(permissions.BasePermission):
    """Allows access only to restaurant servers"""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
            
        # Check claims first
        if hasattr(request.user, 'claims'):
            return request.user.claims.get('role') == 'server'
            
        # Fallback to Firestore check
        employee = firebase_crud.query_collection(
            'employes',
            'firebase_uid',
            '==',
            request.user.uid
        )
        return employee and employee[0].get('role') == 'server'

class IsChef(permissions.BasePermission):
    """Allows access only to kitchen staff (chefs)"""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
            
        # Check claims first
        if hasattr(request.user, 'claims'):
            return request.user.claims.get('role') == 'chef'
            
        # Fallback to Firestore check
        employee = firebase_crud.query_collection(
            'employes',
            'firebase_uid',
            '==',
            request.user.uid
        )
        return employee and employee[0].get('role') == 'chef'

class IsManager(permissions.BasePermission):
    """Allows access only to managers"""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
            
        # Check claims first
        if hasattr(request.user, 'claims'):
            return request.user.claims.get('role') == 'manager'
            
        # Fallback to Firestore check
        employes = firebase_crud.query_collection(
            'employes',
            'firebase_uid',
            '==',
            request.user.uid
        )
        return employes and employes[0].get('role') == 'manager'

class HasManagerPrivileges(permissions.BasePermission):
    """Allows access to managers and users with manager privileges"""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
            
        # Check claims first
        if hasattr(request.user, 'claims'):
            return (
                request.user.claims.get('role') == 'manager' or
                'manager' in request.user.claims.get('privileges', [])
            )
            
        # Fallback to Firestore check
        employes = firebase_crud.query_collection(
            'employes',
            'firebase_uid',
            '==',
            request.user.uid
        )
        return (
            employes and 
            (employes[0].get('role') == 'manager' or
             'manager' in employes[0].get('privileges', []))
        )