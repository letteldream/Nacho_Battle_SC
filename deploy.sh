# npx hardhat run --network avaxfuji scripts/000_deployWETH.ts
# npx hardhat verify --network avaxfuji

# npx hardhat run --network avaxfuji scripts/001_deployTomb.ts
# npx hardhat verify --network avaxfuji 100 0xb5D774a16CF9903353DaeAE188a1954312080D4a

# npx hardhat run --network avaxfuji scripts/002_deployTBond.ts
# npx hardhat verify --network avaxfuji

# npx hardhat run --network avaxfuji scripts/003_deployLuchador.ts
# npx hardhat verify --network avaxfuji ( nacho, nbond, weth)

# npx hardhat run --network avaxfuji scripts/004_deployTrainer.ts
# npx hardhat verify --network avaxfuji (luchardor addr)

# npx hardhat run --network avaxfuji scripts/005_deployBattle.ts
# npx hardhat verify --network avaxfuji ( nacho, nbond, luchardor)
