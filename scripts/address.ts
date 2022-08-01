export const wethAddress = '0x063c8BC02bF3e22C7C12d6583203DB5C7fe868f6' // Grape token
export const tombAddress = '0x5c034F6b00EA1cDf131554feE56063B7f91B3dd4' // Grape token
export const tbondAddress = '0xeC0c8C862ABCbCB10BF6E6254306960c7cdCfaBD' // Grape token
export const luchardorAddress = '0x244Fe7B271757D43DE730b980A0216a2C98D4883' // Vintage wine token
export const trainerAddress = '0xf039B6E8F687ab3d21C19fdE7C07ef1b48A8dE4f'
export const battleAddress = '0x82BFa1D67A5f95d0E871Bf52F2675A00D06389d1'

// npx hardhat run --network rinkeby scripts/000_deployWETH.ts
// npx hardhat verify --network rinkeby ( addr )

// npx hardhat run --network rinkeby scripts/001_deployTomb.ts
// npx hardhat verify --network rinkeby ( addr ) 100 0xb5D774a16CF9903353DaeAE188a1954312080D4a

// npx hardhat run --network rinkeby scripts/002_deployTBond.ts
// npx hardhat verify --network rinkeby ( addr )

// npx hardhat run --network rinkeby scripts/003_deployLuchador.ts
// npx hardhat verify --network rinkeby ( addr ) ( nacho, nbond, weth, 0x5ffcc9f5d9ee5e057878f7a4d0db8cb6d0598b50)

// npx hardhat run --network rinkeby scripts/004_deployTrainer.ts
// npx hardhat verify --network rinkeby (luchardor addr)

// npx hardhat run --network rinkeby scripts/005_deployBattle.ts
// npx hardhat verify --network rinkeby ( nacho, nbond, luchardor)