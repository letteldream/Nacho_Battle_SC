import { ethers } from 'hardhat'
import { tombAddress, tbondAddress, luchardorAddress } from './address'

async function main(): Promise<string> {
  const [deployer] = await ethers.getSigners()
  if (deployer === undefined) throw new Error('Deployer is undefined.')

  console.log('Account balance:', (await deployer.getBalance()).toString())

  const Battle = await ethers.getContractFactory('Battle')
  const Battle_Deployed = await Battle.deploy(
    tombAddress,
    tbondAddress,
    luchardorAddress,
  )

  return Battle_Deployed.address
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
