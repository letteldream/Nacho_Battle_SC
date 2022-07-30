import { ethers } from 'hardhat'

async function main(): Promise<string> {
  const [deployer] = await ethers.getSigners()
  if (deployer === undefined) throw new Error('Deployer is undefined.')

  console.log('Account balance:', (await deployer.getBalance()).toString())

  // const childChainManager = '0xb5D774a16CF9903353DaeAE188a1954312080D4a'

  const MaticWETH = await ethers.getContractFactory('MaticWETH')
  const MaticWETH_Deployed = await MaticWETH.deploy()

  return MaticWETH_Deployed.address
}

main()
  .then((r: string) => {
    console.log('deployed address:', r)
    return r
  })
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
