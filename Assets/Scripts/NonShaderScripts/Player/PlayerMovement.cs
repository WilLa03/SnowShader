using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerMovement : MonoBehaviour
{
    [Tooltip("The players speed.")]
    [SerializeField] private float _walkSpeed = 1;

    [SerializeField] private Camera _camera;
    [SerializeField] private CharacterController _controller;
    
    private bool _shouldMove;
    private Vector3 _direction;
    private Rigidbody _rb;
    private float _speed;

    private Vector3 _velocity;

    //private Animator _animator;
    private void Awake()
    {
        _rb = GetComponent<Rigidbody>();
        Cursor.lockState = CursorLockMode.Locked;
        //_animator = GetComponent<Animator>();
        _speed = _walkSpeed;
    }
    private void Update()
    {
        ApplyGravity();
        CalculateMoveDirection();
        FaceMoveDirection();
        _controller.Move(_velocity * Time.deltaTime);
    }

    private void CalculateMoveDirection()
    {
        Vector3 cameraForward = new Vector3(_camera.transform.forward.x, 0, _camera.transform.forward.z);
        Vector3 cameraRight = new Vector3(_camera.transform.right.x, 0, _camera.transform.right.z);

        Vector3 moveDirection = cameraForward.normalized * _direction.z + cameraRight.normalized * _direction.x;

        _velocity.x = moveDirection.x * _speed;
        _velocity.z = moveDirection.z * _speed;
    }

    private void FaceMoveDirection()
    {
        Vector3 faceDirection = new Vector3(_velocity.x, 0, _velocity.z);
        if(faceDirection == Vector3.zero)return;
        
        transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(faceDirection), 10 * Time.deltaTime);
    }

    private void ApplyGravity()
    {
        if (_velocity.y > Physics.gravity.y)
        {
            _velocity.y += Physics.gravity.y * Time.deltaTime;
        }
    }
    #region InputRelated
    /// <summary>
    /// Input function called by the PlayerInput component. Sets the players movement direction when a button is pushed. _shouldMove is triggered for as long as the button
    /// is pushed.
    /// </summary>
    /// <param name="context">Read from the unity event.</param>
    public void OnMove(InputAction.CallbackContext context)
    {
        _direction = context.ReadValue<Vector3>();
        if(_direction.magnitude > 1) _direction.Normalize();
        _shouldMove = _direction != Vector3.zero;
        /*if (_speed == _walkSpeed)
        {
            _animator.SetBool("Walking", _shouldMove);
            _animator.SetBool("Running", false);
        }

        else if (_speed == _runSpeed)
        {
            _animator.SetBool("Walking", false);
            _animator.SetBool("Running", _shouldMove);
        }
       _animator.SetBool("Idle", !_shouldMove);*/
        
    }
    #endregion

}
