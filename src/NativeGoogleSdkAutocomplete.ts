import {
  TurboModuleRegistry,
  type CodegenTypes,
  type TurboModule,
} from 'react-native';

export interface Spec extends TurboModule {
  initialize(apiKey: string): Promise<void>;
  createSessionToken(): Promise<string>;
  clearSessionToken(token: string): Promise<void>;
  findAutocompletePredictions(
    request: CodegenTypes.UnsafeObject
  ): Promise<CodegenTypes.UnsafeObject[]>;
  fetchPlace(request: CodegenTypes.UnsafeObject): Promise<CodegenTypes.UnsafeObject>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('GoogleSdkAutocomplete');
