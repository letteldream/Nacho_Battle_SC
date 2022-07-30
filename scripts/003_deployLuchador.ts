import { ethers } from 'hardhat'
import { tombAddress, tbondAddress, wethAddress } from './address'

async function main(): Promise<string> {
  const [deployer] = await ethers.getSigners()
  if (deployer === undefined) throw new Error('Deployer is undefined.')

  console.log('Account balance:', (await deployer.getBalance()).toString())

  const Luchardor = await ethers.getContractFactory('Luchador')
  const Luchardor_Deployed = await Luchardor.deploy(
    tombAddress,
    tbondAddress,
    wethAddress,
  )

  return Luchardor_Deployed.address
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
