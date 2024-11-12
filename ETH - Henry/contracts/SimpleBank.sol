// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title SimpleBank
 * @dev Smart contract para gestionar un banco sencillo donde los usuarios pueden registrarse, depositar y retirar ETH.
 */
contract SimpleBank {
    // Estructura que representa la información de cada cliente
    struct User {
        string firstName;         // Nombre del cliente
        string lastName;      // Apellido del cliente
        uint256 balance;     // Saldo actual del cliente en el banco
        bool isRegistered;     // Estado de registro del cliente (true si está registrado)
    }

    // Mapping para asociar direcciones con la estructura User
    mapping(address => User) private users;

    // Variables de estado globales
    address public owner;             // Dirección del propietario del contrato
    address public treasury;          // Dirección de la tesorería
    uint256 public feeBasisPoints;    // Fee en puntos básicos (1% = 100 puntos básicos)
    uint256 public treasuryBalance;   // Balance acumulado en la tesorería

    // Eventos que notifican cuando ocurren acciones específicas en el contrato
    event UserRegistered(address indexed userAddress, string firstName, string lastName);
    event Deposit(address indexed userAddress, uint256 amount);
    event Withdrawal(address indexed userAddress, uint256 amount, uint256 fee);
    event TreasuryWithdrawal(address indexed owner, uint256 amount);

    // Modificador para restringir funciones a usuarios registrados
    modifier onlyRegistered() {
        require(users[msg.sender].isRegistered, "Debe estar registrado.");
        _;
    }

    // Modificador para restringir funciones al propietario
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el propietario puede ejecutar esta funcion.");
        _;
    }

     /**
     * @dev Constructor del contrato
     * @param _fee El fee en puntos básicos (1% = 100 puntos básicos)
     * @param _treasury La dirección de la tesorería
     */
    constructor(uint256 _fee, address _treasury) {
        require(_treasury != address(0), "La direccion de tesoreria no puede ser cero.");
        require(_fee <= 10000, "El fee no puede ser mayor al 100%.");     
        
        // Inicializa las variables de estado
        owner = msg.sender;           // Define al desplegador del contrato
        feeBasisPoints = _fee;        // Configura la comisión en puntos básicos
        treasury = _treasury;         // Asigna la dirección de tesorería
        treasuryBalance = 0;          // Inicializa el balance de la tesorería en cero
    }

   /**
     * @dev Función para registrar un nuevo usuario
     * @param _firstName El primer nombre del usuario
     * @param _lastName El apellido del usuario
     */
    function register(string calldata _firstName, string calldata _lastName) external {
        require(bytes(_firstName).length > 0, "El nombre no puede estar vacio.");
        require(bytes(_lastName).length > 0, "El apellido no puede estar vacio.");
        require(!users[msg.sender].isRegistered, "Usuario ya registrado.");

        // Registra el usuario con los datos proporcionados y un saldo inicial de cero
        users[msg.sender] = User({
            firstName: _firstName,
            lastName: _lastName,
            balance: 0,
            isRegistered: true
        });
        
        // Emite un evento para informar que el usuario ha sido registrado exitosamente
        emit UserRegistered(msg.sender, _firstName, _lastName);
    }

     /**
     * @dev Función para hacer un depósito de ETH en la cuenta del usuario
     */
    function deposit() external payable onlyRegistered {
        require(msg.value > 0, "El deposito debe ser mayor a cero.");

        // Aumenta el saldo del usuario en la cantidad enviada
        users[msg.sender].balance += msg.value;

        // Emite un evento para registrar el depósito de fondos
        emit Deposit(msg.sender, msg.value);
    }

     /**
     * @dev Función para verificar el saldo del usuario
     * @return El saldo del usuario en wei
     */
    function getBalance() external view onlyRegistered returns (uint256) {
        return users[msg.sender].balance;    // Devuelve el saldo actual del usuario
    } 

    /**
     * @dev Función para retirar ETH de la cuenta del usuario
     * @param _amount La cantidad a retirar (en wei)
     */
    function withdraw(uint256 _amount) external onlyRegistered {
        require(_amount > 0, "El monto debe ser mayor a cero.");
        require(users[msg.sender].balance >= _amount, "Saldo insuficiente.");

         // Cálculo del fee en puntos básicos
        uint256 fee = (_amount * feeBasisPoints) / 10000;
        uint256 amountAfterFee = _amount - fee;

        // Actualización de balances
        users[msg.sender].balance -= _amount;
        treasuryBalance += fee;

        // Transferencia de fondos al usuario
        payable(msg.sender).transfer(amountAfterFee);

        // Emite un evento para registrar el retiro de fondos
        emit Withdrawal(msg.sender, _amount, fee);
    }

    /**
     * @dev Función para que el propietario retire fondos de la cuenta de tesorería
     * @param _amount La cantidad a retirar de la tesorería (en wei)
     */
    function withdrawTreasury(uint256 _amount) external onlyOwner {
        require(treasuryBalance >= _amount, "Fondos insuficientes en la tesoreria.");

        // Reduce el balance de la tesorería y transfiere los fondos al owner
        treasuryBalance -= _amount;
        payable(treasury).transfer(_amount);

        // Emite un evento para registrar el retiro de la tesorería
        emit TreasuryWithdrawal(owner, _amount);
    }
}