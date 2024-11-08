// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title SimpleBank
 * @dev Smart contract para gestionar un banco sencillo donde los usuarios pueden registrarse, depositar y retirar ETH.
 */
contract SimpleBank {
    // Estructura que representa la información de cada cliente
    struct Client {
        string name;         // Nombre del cliente
        string surname;      // Apellido del cliente
        uint256 balance;     // Saldo actual del cliente en el banco
        bool registered;     // Estado de registro del cliente (true si está registrado)
    }

    // Mapeo que asocia una dirección con la información del cliente
    mapping(address => Client) private clients;

    // Variables de estado globales
    address public admin;           // Dirección del administrador del contrato (propietario)
    address public fundAccount;     // Dirección de la tesorería para almacenar las comisiones
    uint256 public transactionFee;  // Comisión en puntos básicos para cada retiro (10000 = 100%)
    uint256 public fundBalance;     // Saldo acumulado en la cuenta de la tesorería

    // Eventos que notifican cuando ocurren acciones específicas en el contrato
    event ClientAdded(address indexed clientAddr, string name, string surname);
    event FundsDeposited(address indexed clientAddr, uint256 amount);
    event FundsWithdrawn(address indexed clientAddr, uint256 amount, uint256 feeDeducted);
    event FundWithdrawn(address indexed adminAddr, uint256 amount);

    // Modificador para asegurar que solo los clientes registrados pueden ejecutar ciertas funciones
    modifier onlyClient() {
        require(clients[msg.sender].registered, "No registrado");
        _;
    }

    // Modificador para asegurar que solo el administrador puede ejecutar ciertas funciones
    modifier onlyAdmin() {
        require(msg.sender == admin, "Solo admin");
        _;
    }

     /**
     * @dev Constructor del contrato
     */
    constructor(uint256 _transactionFee, address _fundAccount) {
        require(_fundAccount != address(0), "Direccion no valida"); // Asegura que la dirección de tesorería sea válida
        require(_transactionFee <= 10000, "Cuota no valida");       // La comisión debe ser <= 100%
        
        // Inicializa las variables de estado
        admin = msg.sender;             // Define al desplegador del contrato como el administrador
        transactionFee = _transactionFee; // Configura la comisión en puntos básicos
        fundAccount = _fundAccount;     // Asigna la dirección de tesorería
        fundBalance = 0;                // Inicializa el balance de la tesorería en cero
    }

   /**
     * @dev Función para registrar un nuevo usuario
     */
    function signUp(string calldata _name, string calldata _surname) external {
        require(bytes(_name).length > 0, "Nombre requerido");         // El nombre no debe estar vacío
        require(bytes(_surname).length > 0, "Apellido requerido");     // El apellido no debe estar vacío
        require(!clients[msg.sender].registered, "Cliente ya registrado"); // Verifica que el cliente no esté ya registrado

        // Registra el cliente con los datos proporcionados y un saldo inicial de cero
        clients[msg.sender] = Client(_name, _surname, 0, true);
        
        // Emite un evento para informar que el cliente ha sido registrado exitosamente
        emit ClientAdded(msg.sender, _name, _surname);
    }

     /**
     * @dev Función para hacer un depósito de ETH en la cuenta del usuario
     */
    function addFunds() external payable onlyClient {
        require(msg.value > 0, "Monto debe ser mayor a cero"); // Verifica que el monto sea positivo

        // Aumenta el saldo del cliente en la cantidad enviada
        clients[msg.sender].balance += msg.value;

        // Emite un evento para registrar el depósito de fondos
        emit FundsDeposited(msg.sender, msg.value);
    }

     /**
     * @dev Función para verificar el saldo del usuario
     * @return El saldo del usuario en wei
     */
    function checkBalance() external view onlyClient returns (uint256) {
        return clients[msg.sender].balance; // Devuelve el saldo actual del cliente
    }

    /**
     * @dev Función para retirar ETH de la cuenta del usuario
     * @param _amount La cantidad a retirar (en wei)
     */
    function takeOutFunds(uint256 _amount) external onlyClient {
        require(_amount > 0, "Monto debe ser positivo");                  // El monto a retirar debe ser positivo
        require(clients[msg.sender].balance >= _amount, "Fondos insuficientes"); // Verifica que el saldo del cliente sea suficiente

        // Calcula la comisión basada en el monto de retiro y en los puntos básicos
        uint256 feeAmount = (_amount * transactionFee) / 10000;
        uint256 amountAfterFee = _amount - feeAmount;  // Monto que recibirá el cliente tras deducir la comisión

        // Actualiza el saldo del cliente y agrega la comisión a la tesorería
        clients[msg.sender].balance -= _amount;
        fundBalance += feeAmount;

        // Transfiere el monto después de la comisión al cliente
        payable(msg.sender).transfer(amountAfterFee);

        // Emite un evento para registrar el retiro de fondos
        emit FundsWithdrawn(msg.sender, amountAfterFee, feeAmount);
    }

    /**
     * @dev Función para que el propietario retire fondos de la cuenta de tesorería
     * @param _amount La cantidad a retirar de la tesorería (en wei)
     */
    function retrieveFunds(uint256 _amount) external onlyAdmin {
        require(fundBalance >= _amount, "Fondos insuficientes en cuenta"); // Verifica que haya suficiente balance en la tesorería

        // Reduce el balance de la tesorería y transfiere los fondos al administrador
        fundBalance -= _amount;
        payable(msg.sender).transfer(_amount);

        // Emite un evento para registrar el retiro de la tesorería
        emit FundWithdrawn(admin, _amount);
    }
}