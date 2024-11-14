// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


/**
 * @title ICounter
 * @dev Interfaz simple para un contador.
 * Define las funciones mínimas que cualquier contrato contador debe tener.
 */
interface ICounter {
    /**
     * @notice Incrementa el valor del contador.
     */
    function increment() external;

    /**
     * @notice Obtiene el valor actual del contador.
     * @return El valor actual del contador.
     */
    function getCount() external view returns (uint256);
}

/**
 * @title Counter
 * @dev Implementación de un contrato contador que sigue la interfaz ICounter.
 * Permite incrementar un contador y obtener su valor.
 */
contract Counter is ICounter {
    uint256 private count;

    /**
     * @dev Constructor que inicializa el contador en cero.
     */
    constructor() {
        count = 0;
    }


    /**
     * @notice Incrementa el valor del contador en 1.
     * Implementación de la función `increment` de la interfaz ICounter.
     */
    function increment() external override {
        count += 1;
    }

    /**
     * @notice Obtiene el valor actual del contador.
     * @return El valor actual del contador.
     * Implementación de la función `getCount` de la interfaz ICounter.
     */
    function getCount() external view override returns (uint256) {
        return count;
    }
}

/**
 * @title CounterUser
 * @dev Contrato que interactúa con un contrato contador utilizando la interfaz ICounter.
 */
contract CounterUser {
    ICounter public counterContract;

    /**
     * @dev Constructor que recibe la dirección de un contrato que implementa ICounter.
     * @param _counterContract Dirección del contrato contador.
     */
    constructor(ICounter _counterContract) {
        counterContract = _counterContract;
    }

    /**
     * @notice Llama a la función `increment` del contrato contador.
     * Incrementa el valor del contador en el contrato `Counter`.
     */
    function incrementCounter() external {
        counterContract.increment();
    }

    /**
     * @notice Obtiene el valor actual del contador desde el contrato `Counter`.
     * @return El valor actual del contador.
     */
    function getCounterValue() external view returns (uint256) {
        return counterContract.getCount();
    }
}
